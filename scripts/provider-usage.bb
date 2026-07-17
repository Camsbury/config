#!/usr/bin/env bb
;; Fetch Claude Code and Codex subscription usage from their OAuth endpoints.
;;
;; Credentials are decoded from ECA's global OAuth cache at:
;;   ~/.cache/eca/db.transit.json
;;
;; The cache is opened read-only. Tokens stay in memory and are never printed.
;; Only subscription OAuth records are accepted; manual API keys are rejected.
;;
;; Usage:
;;   scripts/provider-usage.bb
;;   scripts/provider-usage.bb --provider claude
;;   scripts/provider-usage.bb --provider codex --json
;;   scripts/provider-usage.bb --self-test

(ns provider-usage
  (:require [babashka.http-client :as http]
            [cheshire.core :as json]
            [clojure.java.io :as io]
            [clojure.java.shell :as shell]
            [clojure.string :as str]
            [cognitect.transit :as transit]))

(def ^:private claude-usage-url
  "https://api.anthropic.com/api/oauth/usage")

(def ^:private codex-usage-url
  "https://chatgpt.com/backend-api/wham/usage")

(def ^:private request-timeout-ms 15000)

(def ^:private eca-auth-cache
  (io/file (System/getProperty "user.home") ".cache" "eca" "db.transit.json"))

(defn- nonblank [value]
  (when-let [trimmed (some-> value str str/trim)]
    (when-not (str/blank? trimmed)
      trimmed)))

(defn- read-eca-auth []
  (when-not (.isFile eca-auth-cache)
    (throw (ex-info (str "ECA OAuth cache not found: " eca-auth-cache)
                    {:kind :auth-cache})))
  (try
    (with-open [input (io/input-stream eca-auth-cache)]
      (let [database (transit/read (transit/reader input :json))]
        (or (:auth database) {})))
    (catch Exception _
      (throw (ex-info (str "Could not decode ECA OAuth cache: " eca-auth-cache)
                      {:kind :auth-cache})))))

(defn- number-value [value]
  (cond
    (number? value) (double value)
    (string? value) (try
                      (Double/parseDouble value)
                      (catch NumberFormatException _ nil))
    :else nil))

(defn- integer-value [value]
  (some-> (number-value value) Math/round long))

(defn- clamp [value low high]
  (max low (min high value)))

(defn- remaining-percent [used]
  (when-let [used (number-value used)]
    (clamp (- 100.0 used) 0.0 100.0)))

(defn- epoch->iso [seconds]
  (when-let [seconds (integer-value seconds)]
    (when (pos? seconds)
      (str (java.time.Instant/ofEpochSecond seconds)))))

(defn- quota-row [id label utilization reset-at]
  (when-let [remaining (remaining-percent utilization)]
    {:id id
     :label label
     :remaining-percent remaining
     :reset-at (nonblank reset-at)}))

(defn parse-claude-usage
  "Normalize an Anthropic OAuth usage response. Input is a keyword-keyed map."
  [body]
  (let [windows   [[:five_hour "session" "Session"]
                   [:seven_day "weekly" "Weekly"]
                   [:seven_day_fable "fable" "Fable weekly"]]
        limits    (keep (fn [[source id label]]
                          (let [window (get body source)]
                            (when (map? window)
                              (quota-row id label
                                         (:utilization window)
                                         (:resets_at window)))))
                        windows)
        extra     (:extra_usage body)
        extra-row (when (and (map? extra) (:is_enabled extra))
                    (when-let [row (quota-row "extra" "Extra usage"
                                              (:utilization extra) nil)]
                      (cond-> row
                        (number-value (:monthly_limit extra))
                        (assoc :monthly-limit
                               (number-value (:monthly_limit extra)))

                        (number-value (:used_credits extra))
                        (assoc :used-credits
                               (number-value (:used_credits extra))))))]
    {:provider "claude"
     :status   "ok"
     :limits   (cond-> (vec limits) extra-row (conj extra-row))}))

(defn- window-kind [window fallback]
  (let [seconds (integer-value (:limit_window_seconds window))]
    (cond
      (and seconds (>= seconds (* 6 24 60 60))) "weekly"
      (and seconds (<= seconds (* 24 60 60))) "session"
      :else fallback)))

(defn- codex-window-row [id label window]
  (when (map? window)
    (when-let [remaining (remaining-percent (:used_percent window))]
      {:id id
       :label label
       :remaining-percent remaining
       :reset-at (epoch->iso (:reset_at window))})))

(defn- slug [value]
  (some-> value
          str/lower-case
          (str/replace #"[^a-z0-9]+" "-")
          (str/replace #"(^-|-$)" "")
          nonblank))

(defn- spark-limit? [limit]
  (some #(str/includes? (str/lower-case (or % "")) "spark")
        [(:limit_name limit) (:metered_feature limit)]))

(defn- additional-limit-rows [limit]
  (let [rate-limit (:rate_limit limit)
        primary (:primary_window rate-limit)
        secondary (:secondary_window rate-limit)]
    (if (spark-limit? limit)
      (keep identity
            [(codex-window-row "codex-spark" "Codex Spark" primary)
             (codex-window-row "codex-spark-weekly"
                               "Codex Spark weekly" secondary)])
      (let [source (or (nonblank (:metered_feature limit))
                       (nonblank (:limit_name limit)))
            window (or primary secondary)]
        (when-let [source-slug (slug source)]
          (when-let [row (codex-window-row (str "codex-" source-slug)
                                            source window)]
            [row]))))))

(defn- dedupe-limits [limits]
  (second
   (reduce (fn [[seen rows] row]
             (if (contains? seen (:id row))
               [seen rows]
               [(conj seen (:id row)) (conj rows row)]))
           [#{} []]
           limits)))

(defn parse-codex-usage
  "Normalize a ChatGPT wham usage response. Input is a keyword-keyed map."
  [body]
  (let [rate-limit (:rate_limit body)
        primary (:primary_window rate-limit)
        secondary (:secondary_window rate-limit)
        primary-kind (window-kind primary "session")
        secondary-kind (window-kind secondary "weekly")
        standard (keep identity
                       [(codex-window-row (str "codex-" primary-kind)
                                          (if (= primary-kind "weekly")
                                            "Weekly"
                                            "Session")
                                          primary)
                        (codex-window-row (str "codex-" secondary-kind)
                                          (if (= secondary-kind "session")
                                            "Session"
                                            "Weekly")
                                          secondary)])
        additional (mapcat additional-limit-rows
                           (or (:additional_rate_limits body) []))]
    {:provider "codex"
     :status "ok"
     :plan (:plan_type body)
     :limit-reached (boolean (:limit_reached rate-limit))
     :limits (dedupe-limits (concat standard additional))}))

(defn- error-result
  ([provider kind message]
   (error-result provider kind message nil))
  ([provider kind message status]
   (cond-> {:provider provider
            :status "error"
            :error {:kind kind :message message}}
     status (assoc-in [:error :http-status] status))))

(defn- request-json [provider url headers]
  (try
    (let [{:keys [status body]}
          (http/get url {:headers headers
                         :throw false
                         :timeout request-timeout-ms})]
      (cond
        (not (<= 200 status 299))
        (error-result provider "http"
                      (str "Provider returned HTTP " status) status)

        (not (string? body))
        (error-result provider "response" "Provider returned a non-text body")

        :else
        (try
          {:body (json/parse-string body true)}
          (catch Exception _
            (error-result provider "json"
                          "Provider returned invalid JSON")))))
    (catch Exception _
      (error-result provider "network" "Provider request failed"))))

(defn- fetch-claude [token]
  (let [response (request-json
                  "claude"
                  claude-usage-url
                  {"Accept" "application/json"
                   "Authorization" (str "Bearer " token)
                   "anthropic-beta" "oauth-2025-04-20"})]
    (if-let [body (:body response)]
      (parse-claude-usage body)
      response)))

(defn- fetch-codex [token account-id]
  (let [headers (cond-> {"Accept" "application/json"
                         "Authorization" (str "Bearer " token)}
                  account-id (assoc "ChatGPT-Account-Id" account-id))
        response (request-json "codex" codex-usage-url headers)]
    (if-let [body (:body response)]
      (parse-codex-usage body)
      response)))

(defn- auth-result [provider kind message]
  {:provider provider
   :status "not-configured"
   :error {:kind kind :message message}})

(defn- oauth-credential [auth eca-provider output-provider]
  (let [record (get auth eca-provider)]
    (cond
      (not (map? record))
      (auth-result output-provider "missing-oauth"
                   (str "ECA has no saved OAuth login for " eca-provider))

      (not= :auth/oauth (:type record))
      (auth-result output-provider "wrong-auth-type"
                   (str "ECA " eca-provider
                        " authentication is not subscription OAuth"))

      (not (nonblank (:api-key record)))
      (auth-result output-provider "missing-access-token"
                   (str "ECA " eca-provider
                        " OAuth record has no access token"))

      :else
      {:credential {:access-token (:api-key record)
                    :account-id (:account-id record)
                    :expires-at (:expires-at record)}})))

(defn- credentials []
  (let [auth (read-eca-auth)]
    {:claude (oauth-credential auth "anthropic" "claude")
     :codex (oauth-credential auth "openai" "codex")}))

(defn- fetch-provider [provider credentials]
  (let [entry (get credentials provider)]
    (if-let [{:keys [access-token account-id]} (:credential entry)]
      (case provider
        :claude (fetch-claude access-token)
        :codex (fetch-codex access-token account-id))
      entry)))

(defn- requested-providers [requested]
  (case requested
    :claude [:claude]
    :codex [:codex]
    :all [:claude :codex]))

(defn- fetch-results [requested credentials]
  (mapv #(fetch-provider % credentials)
        (requested-providers requested)))

(defn- percentage-text [value]
  (if (== value (Math/rint value))
    (format "%.0f%%" value)
    (format "%.1f%%" value)))

(defn- format-duration
  "Concise days/hours/minutes label for a count of SECONDS.
Drops leading zero units but always keeps minutes: 183300 -> \"2d 3h 15m\",
5400 -> \"1h 30m\", 900 -> \"15m\". Non-positive input yields \"now\"."
  [secs]
  (if (neg? secs)
    "now"
    (let [days (quot secs 86400)
          hours (quot (mod secs 86400) 3600)
          mins (quot (mod secs 3600) 60)]
      (str/join " "
                (cond-> []
                  (pos? days) (conj (str days "d"))
                  (or (pos? days) (pos? hours)) (conj (str hours "h"))
                  :always (conj (str mins "m")))))))

(defn- reset-in
  "Time from now until an ISO instant, as a d/h/m label (e.g. \"2d 3h 15m\").
Parses both offset (\"...+00:00\") and zulu (\"...Z\") instants; on a parse
failure the raw string is returned unchanged."
  [iso]
  (try
    (let [target (.toInstant (java.time.OffsetDateTime/parse iso))
          secs (.getSeconds (java.time.Duration/between
                             (java.time.Instant/now) target))]
      (format-duration secs))
    (catch Exception _ iso)))

(defn- provider-notification
  "Build a {:title :body} pair summarizing one provider result for dunst."
  [{:keys [provider status plan limit-reached limits error]}]
  {:title (str (str/capitalize provider)
               (when plan (str " (" plan ")"))
               " usage")
   :body
   (case status
     "ok"
     (let [rows (if (seq limits)
                  (map (fn [{:keys [label remaining-percent reset-at]}]
                         (str label ": "
                              (percentage-text remaining-percent)
                              " left"
                              (when reset-at
                                (str " (resets in " (reset-in reset-at) ")"))))
                       limits)
                  ["No quota windows returned"])]
       (str/join "\n" (cond->> rows limit-reached (cons "Limit reached"))))
     "not-configured" (str "Not configured: " (:message error))
     "error" (str "Error: " (:message error))
     (str "Unknown status: " status))})

(defn- notify-provider!
  "Send one dunst notification for a provider result via notify-send."
  [result]
  (let [{:keys [title body]} (provider-notification result)
        urgency (if (= "error" (:status result)) "critical" "normal")]
    (shell/sh "notify-send" "--app-name=provider-usage"
              (str "--urgency=" urgency) title body)))

(defn- print-provider [{:keys [provider status plan limit-reached limits error]}]
  (println (str (str/capitalize provider)
                (when plan (str " (" plan ")"))))
  (case status
    "ok"
    (do
      (when limit-reached
        (println "  Limit reached"))
      (if (seq limits)
        (doseq [{:keys [label remaining-percent reset-at
                        monthly-limit used-credits]} limits]
          (println (str "  " label ": "
                        (percentage-text remaining-percent)
                        " remaining"
                        (when reset-at (str ", resets in " (reset-in reset-at)))))
          (when (or monthly-limit used-credits)
            (println (str "    credits: " (or used-credits "?")
                          " used of " (or monthly-limit "?")))))
        (println "  No quota windows returned")))

    "not-configured"
    (println (str "  Not configured: " (:message error)))

    "error"
    (println (str "  Error: " (:message error)))

    (println (str "  Unknown status: " status)))
  (println))

(defn- exit-code [results]
  (cond
    (every? #(= "not-configured" (:status %)) results) 2
    (some #(= "error" (:status %)) results) 1
    :else 0))

(defn- parse-provider [value]
  (case value
    "all" :all
    "claude" :claude
    "codex" :codex
    (throw (ex-info (str "Unknown provider: " value)
                    {:kind :usage}))))

(defn- parse-args [args]
  (loop [remaining args
         options {:provider :all :json? false :self-test? false :help? false
                  :notify? false}]
    (if-let [[arg & more] (seq remaining)]
      (case arg
        "--provider" (if-let [value (first more)]
                       (recur (rest more)
                              (assoc options :provider
                                     (parse-provider value)))
                       (throw (ex-info "--provider requires a value"
                                       {:kind :usage})))
        "--json" (recur more (assoc options :json? true))
        "--notify" (recur more (assoc options :notify? true))
        "--self-test" (recur more (assoc options :self-test? true))
        "--help" (recur more (assoc options :help? true))
        "-h" (recur more (assoc options :help? true))
        (throw (ex-info (str "Unknown argument: " arg) {:kind :usage})))
      options)))

(defn- print-help []
  (println "Fetch Claude Code and Codex subscription usage.")
  (println)
  (println "Usage:")
  (println "  scripts/provider-usage.bb [--provider all|claude|codex] [--json] [--notify]")
  (println "  scripts/provider-usage.bb --self-test")
  (println)
  (println "  --notify sends one dunst notification per provider via notify-send.")
  (println)
  (println "Credentials:")
  (println "  Reads Anthropic Max and OpenAI subscription OAuth records from")
  (println "  ~/.cache/eca/db.transit.json. Manual API keys are not used."))

(defn- check! [description predicate]
  (when-not predicate
    (throw (ex-info (str "Self-test failed: " description) {}))))

(defn- self-test! []
  (let [claude (parse-claude-usage
                {:five_hour {:utilization 28.5
                             :resets_at "2026-07-15T18:00:00Z"}
                 :seven_day {:utilization 61}
                 :extra_usage {:is_enabled true
                               :monthly_limit 100.0
                               :used_credits 20.0
                               :utilization 20.0}})
        codex (parse-codex-usage
               {:plan_type "pro"
                :rate_limit
                {:limit_reached false
                 :primary_window {:used_percent "20"
                                  :reset_at 1784148000
                                  :limit_window_seconds 18000}
                 :secondary_window {:used_percent 65.5
                                    :reset_at 1784678400
                                    :limit_window_seconds 604800}}
                :additional_rate_limits
                [{:limit_name "Codex Spark"
                  :rate_limit
                  {:primary_window {:used_percent 10
                                    :limit_window_seconds 18000}
                   :secondary_window {:used_percent 30
                                      :limit_window_seconds 604800}}}
                 {:metered_feature "GPT-5.4 Mini"
                  :rate_limit
                  {:primary_window {:used_percent 40}}}]})
        oauth-auth {"anthropic" {:type :auth/oauth
                                  :api-key "fixture-claude-token"}
                    "openai" {:type :auth/oauth
                              :api-key "fixture-codex-token"
                              :account-id "fixture-account"}}
        claude-auth (oauth-credential oauth-auth "anthropic" "claude")
        codex-auth (oauth-credential oauth-auth "openai" "codex")
        manual-auth (oauth-credential
                     {"anthropic" {:type :auth/token
                                    :api-key "fixture-manual-key"}}
                     "anthropic" "claude")
        http-error (with-redefs [http/get (fn [& _]
                                            {:status 401 :body "{}"})]
                     (request-json "claude" "https://example.invalid" {}))]
    (check! "Claude session remaining percentage"
            (= 71.5 (get-in claude [:limits 0 :remaining-percent])))
    (check! "Claude extra usage values"
            (= 20.0 (get-in claude [:limits 2 :used-credits])))
    (check! "Codex plan"
            (= "pro" (:plan codex)))
    (check! "Codex session remaining percentage"
            (= 80.0 (get-in codex [:limits 0 :remaining-percent])))
    (check! "Codex weekly remaining percentage"
            (= 34.5 (get-in codex [:limits 1 :remaining-percent])))
    (check! "Codex Spark windows"
            (= #{"codex-spark" "codex-spark-weekly"}
               (->> (:limits codex)
                    (map :id)
                    (filter #(str/starts-with? % "codex-spark"))
                    set)))
    (check! "Generic Codex additional limit"
            (= 60.0
               (->> (:limits codex)
                    (filter #(= "codex-gpt-5-4-mini" (:id %)))
                    first
                    :remaining-percent)))
    (check! "Anthropic OAuth access token mapping"
            (= "fixture-claude-token"
               (get-in claude-auth [:credential :access-token])))
    (check! "OpenAI OAuth account mapping"
            (= "fixture-account"
               (get-in codex-auth [:credential :account-id])))
    (check! "Manual API keys are rejected"
            (= "wrong-auth-type"
               (get-in manual-auth [:error :kind])))
    (check! "HTTP status is preserved"
            (= 401 (get-in http-error [:error :http-status])))
    (check! "Duration drops leading zero units, keeps minutes"
            (= ["2d 3h 15m" "1h 30m" "15m" "now"]
               [(format-duration (+ (* 2 86400) (* 3 3600) (* 15 60)))
                (format-duration 5400)
                (format-duration 900)
                (format-duration -5)]))
    (println "provider-usage self-test: 12 checks passed")))

(defn -main [& args]
  (try
    (let [{:keys [provider json? self-test? help? notify?]} (parse-args args)]
      (cond
        help? (print-help)
        self-test? (self-test!)
        :else
        (let [results (fetch-results provider (credentials))
              output {:fetched-at (str (java.time.Instant/now))
                      :providers results}
              code (exit-code results)]
          (when notify?
            (doseq [result results]
              (notify-provider! result)))
          (if json?
            (println (json/generate-string output {:pretty true}))
            (doseq [result results]
              (print-provider result)))
          (when-not (zero? code)
            (System/exit code)))))
    (catch clojure.lang.ExceptionInfo error
      (binding [*out* *err*]
        (println (str "error: " (.getMessage error)))
        (when (= :usage (:kind (ex-data error)))
          (println "Run with --help for usage.")))
      (System/exit 2))))

(apply -main *command-line-args*)
