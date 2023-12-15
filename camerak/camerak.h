{:keymap
 [:main-l
  {:left
   {:outer-vert [:noop :tab [:hold-layer :sym-l :lbracket] :lspo]
    :inner-vert [[:lctl :q]
                 [:lgui :x] ; M-x
                 :caps]
    :top-hor    [:page-down
                 :page-up
                 :prev-track
                 :next-track
                 :play-pause]
    :bot-hor    [[:hyper :noop] :lalt [:lsft [:lalt :noop]] [:meh :noop] :lgui]
    :main-0     [:q :w :f :p :g]
    :main-1     [:a :r :s :t :d]
    :main-2     [:z :x :c :v :b]
    :thumb      [:noop :noop :noop :space [:hold-layer :num-l :esc] [:ctl-t :noop]]}
   :right
   {:outer-vert [:noop :delete [:hold-layer :sym-l] :rspc]
    :inner-vert [:noop :app :noop]
    :top-hor    [:mute :vol-up :vol-down [:lgui :kp-plus] [:lgui :kp-minus]]
    :bot-hor    [:lgui [:meh :noop] [:lsft [:lalt :noop]] :lalt [:hyper :noop]]
    :main-0     [:j :l :u :y :coln]
    :main-1     [:h :n :e :i :o]
    :main-2     [:k :m :comma :dot :slash]
    :thumb      [:noop :noop :noop [:clt-t :noop] [:hold-layer :num-l :enter] :bspace]}}

  :sym-l
  {:left  {:outer-vert [:noop :noop :trns :lcbr]
           :inner-vert [:noop :noop :noop]
           :top-hor [:noop :noop :noop :noop :noop]
           :bot-hor [:noop :noop :noop :noop :noop]
           :main-0  [:dlr  :circ :hash :unds :noop]
           :main-1  [:plus :aster :equal :minus :ques]
           :main-2  [:left :down :up :right :no]
           :thumb   [:noop :reset :noop :noop :noop]}
   :right {:outer-vert [:noop :noop :trns :rcbr]
           :inner-vert [:noop :noop :noop]
           :top-hor [:noop :noop :noop :noop :noop]
           :bot-hor [:noop :noop :noop :noop :noop]
           :main-0  [:noop :at  :perc :pipe :scolon]
           :main-1  [:exlm :quote :dquo :grave :tild]
           :main-2  [:noop :amp :lt :gt :bslash]
           :thumb   [:f13 :noop :noop :noop [:to :braid-l] :noop]}}

  :num-l
  {:left  {:outer-vert [:inspect-linux :noop :noop :lctl]
           :inner-vert [:inspec-mac :noop :noop]
           :top-hor [:f1 :f2 :f3 :f4 :f5]
           :bot-hor [:noop :lalt :noop :noop :noop]
           :main-0  [[:lalt 1] [:lalt 2] [:lalt 3] [:lalt 4] [:lalt 5]]
           :main-1  [1 2 3 4 5]
           :main-2  [[:lsft [:lalt 1]]
                     [:lsft [:lalt 2]]
                     [:lsft [:lalt 3]]
                     [:lsft [:lalt 4]]
                     [:lsft [:lalt 5]]]
           :thumb   [:noop :noop :noop :trns :noop]}
           ;;;
   :right {:outer-vert [:f11 :f12 :noop :lctl]
           :inner-vert [:noop :noop :noop]
           :top-hor [:f6 :f7 :f8 :f9 :f10]
           :bot-hor [:noop :noop :noop :lalt :noop]
           :main-0  [[:lalt 6] [:lalt 7] [:lalt 8] [:lalt 9] [:lalt 0]]
           :main-1  [6 7 8 9 0]
           :main-2  [[:lsft [:lalt 6]]
                     [:lsft [:lalt 7]]
                     [:lsft [:lalt 8]]
                     [:lsft [:lalt 9]]
                     [:lsft [:lalt 0]]]
           :thumb   [:noop :noop :noop :noop :trns :noop]}}

  :braid-l {}]
 :macros
 {:inspect-mac   [:lgui [:lsft :c]]
  :inspect-linux [:lctl [:lsft :j]]}}
