;; -*- lexical-binding: t; -*-
;;
;; config/theme/editor.el -- load doom themes from EDN, and (later) edit them
;; live.  This file is the Emacs side of the "EDN is the source of truth"
;; design: `doom-molokam.edn' is parsed and assembled into a `def-doom-theme'
;; form, so the theme is derivable from EDN and hand/tool edits to the EDN can
;; be re-applied to the running Emacs performantly.
;;
;; The EDN files are pure DATA with NO symbols (a user ruling); this file is
;; both their compiler and their documentation.  The goal is RENDER-equivalence,
;; not byte-parity with the old hand-written `.el': loading the EDN reproduces
;; the same resolved palette and face attributes.  The earlier byte-for-byte
;; `.el' round-trip was migration scaffolding and has been intentionally retired
;; -- it forced transcribing elisp reader syntax (quasiquote/unquote/car) into
;; the EDN, which is exactly what the no-symbols rule forbids.  Equivalence is
;; checked by diffing a full `face-all-attributes' dump before/after a reload.
;; See `.eca/docs/reference/theme-editor-crash-postmortem.md' for why we persist
;; to disk first and test deliberately.

(require 'prelude)

;; `cmacs-config-path' is a core/env global; `ck/doom-theme-dir' is this file's
;; own var, forward-referenced from `ck/doom-theme--structural-data' before its
;; `defvar' below.  filenotify's watch fns are called only at runtime.
(declare-vars cmacs-config-path ck/doom-theme-dir)
(declare-functions "filenotify" file-notify-add-watch file-notify-rm-watch)

(defvar ck/doom-theme-edn-file
  (expand-file-name "config/theme/doom-molokam.edn" cmacs-config-path)
  "Path to the EDN source of the active editable doom theme.")

;;; EDN -> elisp translation -------------------------------------------------
;;
;; EDN has no reader macros for elisp quoting, so the EDN uses explicit forms
;; that we translate back here:
;;   - a vector []            -> a quoted list  (a [gui 256 16] color triple)
;;   - (quote x)              -> 'x
;;   - (quasiquote x)         -> `x   (built with the reader's backquote symbol)
;;   - (unquote x)            -> ,x
;;   - (unquote-splicing x)   -> ,@x
;; Any other list is a verbatim elisp form (doom-lighten, if, when, ...) whose
;; elements are translated structurally.  Symbols/atoms pass through unchanged;
;; doom's own colorizer later rewrites color-named symbols into `doom-color'
;; lookups, exactly as it does for the hand-written .el theme.

(defun ck/doom-theme--translate (x)
  "Translate EDN-parsed datum X into an elisp theme form."
  (cond
   ((vectorp x)
    ;; a color triple (the only vectors that reach here): quote the list form
    (list 'quote (mapcar #'ck/doom-theme--translate (append x nil))))
   ((consp x)
    (let ((head (car x)))
      (cond
       ((eq head 'quote)            (list 'quote (cadr x)))
       ((eq head 'quasiquote)       (list (intern "`")  (ck/doom-theme--translate (cadr x))))
       ((eq head 'unquote)          (list (intern ",")  (ck/doom-theme--translate (cadr x))))
       ((eq head 'unquote-splicing) (list (intern ",@") (ck/doom-theme--translate (cadr x))))
       (t (mapcar #'ck/doom-theme--translate x)))))
   (t x)))

;;; Form assembly ------------------------------------------------------------

(defun ck/doom-theme--build-defs (defs)
  "Build the `def-doom-theme' let-binding list from DEFS.
DEFS is the vector of (name value) pairs from the EDN `:defs' (or `:vars')."
  (mapcar (lambda (pair)
            (list (car pair) (ck/doom-theme--translate (cadr pair))))
          (append defs nil)))

(defun ck/doom-theme--build-faces (faces)
  "Build the `def-doom-theme' extra-faces list from FACES.
FACES is the vector of face specs from the EDN `:faces'."
  (mapcar #'ck/doom-theme--translate (append faces nil)))

(defun ck/doom-theme--build-toggles (name toggles)
  "Return the defgroup + defcustom forms for a theme NAME's TOGGLES.
NAME is the theme symbol (e.g. `doom-molokam'); TOGGLES is the EDN
`:toggles' hash-table keyed by keyword (`:brighter-comments' -> variable
`doom-molokam-brighter-comments').  Returns nil when TOGGLES is empty."
  (when (hash-table-p toggles)
    (let ((group (intern (format "%s-theme" name)))
          forms)
      (push `(defgroup ,group nil
               ,(format "Options for the `%s' theme." name)
               :group 'doom-themes)
            forms)
      (maphash
       (lambda (key spec)
         (let* ((kname (if (keywordp key) (substring (symbol-name key) 1)
                         (format "%s" key)))
                (var (intern (format "%s-%s" name kname)))
                (default (gethash :default spec))
                (doc (or (gethash :doc spec) ""))
                (type (or (gethash :type spec) 'boolean)))
           (push `(defcustom ,var ,default ,doc
                    :group ',group
                    :type ',type)
                 forms)))
       toggles)
      (nreverse forms))))

(defun ck/doom-theme--assemble (name doc defs faces vars)
  "Assemble a `def-doom-theme' form from FINAL elisp parts.
DEFS/VARS are let-binding lists ((sym form) ...); FACES a face-spec list.
Shared by the flat-classic and semantic compile paths."
  `(def-doom-theme ,name ,doc
     ,defs
     ,faces
     ,(when (and vars (> (length vars) 0)) vars)))

(defun ck/doom-theme--build-form (data)
  "Assemble the `def-doom-theme' form from flat-classic EDN DATA (hash-table)."
  (ck/doom-theme--assemble
   (gethash :name data) (gethash :doc data)
   (ck/doom-theme--build-defs (gethash :defs data))
   (ck/doom-theme--build-faces (gethash :faces data))
   (ck/doom-theme--build-defs (gethash :vars data))))

;;; Reading / applying -------------------------------------------------------

(defun ck/doom-theme--parse (string)
  "Parse EDN STRING into its top-level elisp hash-table."
  (require 'parseedn)
  (parseedn-read-str string))

(defun ck/doom-theme--read-edn (file)
  "Parse EDN FILE into an elisp hash-table (its top-level map)."
  (ck/doom-theme--parse
   (with-temp-buffer
     (insert-file-contents file)
     (buffer-string))))

;;; Semantic compile (three-tier -> def-doom-theme) --------------------------
;;
;; A theme EDN written in the semantic three-tier form (`:palette', `:roles',
;; `:families', `:extends') is compiled here into the same `def-doom-theme'
;; form the verified assembler produces, so the round-trip guarantee carries.
;;
;; EDN convention: the files are PURE DATA -- no symbols anywhere (by user
;; ruling).  Everything an elisp theme needs is encoded as keywords, strings,
;; numbers, booleans, vectors, and maps, and `ck/doom-theme--xlate' maps it
;; back onto elisp:
;;   - a keyword that NAMES a :palette or :roles entry resolves to that color
;;     symbol; any OTHER keyword becomes a quoted literal symbol (:bold, :wave,
;;     :unspecified, :italic, an :inherit face name, ...);
;;   - color math is a closed grammar: a vector [:lighten C amt] / [:darken C
;;     amt] (nestable) -- these two ops are all that is allowed;
;;   - a [gui term256 term16] triple is a plain 3-string vector;
;;   - EDN true/false/nil map to elisp t/nil (so no `t'/`nil' symbols);
;;   - a nested plist (an :underline or :box spec) is written as a map.
;;   :palette {:name [gui 256 16], ...}   -> leading let-bindings (primitives)
;;   :roles   {:name expr, ...}           -> trailing let-bindings (semantics)
;;   :faces   {:face {:prop val}}         -> face overrides (:&override marker)
;;   :families {:rainbow [...] :outline [...]} -> generated face specs
;;   :extends "structural"                -> merge that file's :faces UNDER these
;; The theme :name is a string, interned on compile.  Themes carry no :toggles;
;; the toggle plumbing below stays only as dormant capability.
;; Map insertion order is preserved, so :palette emits before :roles (roles
;; reference palette colors, not vice versa).
;;
;; The EDN files (`doom-molokam.edn', `structural.edn') are pure data, no
;; comments -- this file is their documentation.  `structural.edn' is the shared
;; boilerplate layer, seeded from doom-molokam's own face overrides (molokam
;; descends from an old molokai) and generalized into role terms so future
;; themes reuse it.  It is applied over `doom-themes-base', so its face set is
;; intentionally bounded to what molokam overrode -- that is why loading molokam
;; via EDN reproduces the hand-written .el look exactly.  The two repeated groups
;; molokam had (rainbow-delimiters depth 1-7, outline 1-2) are NOT in structural;
;; they are generated from each theme's `:families' shorthands instead.

(defun ck/doom-theme--semantic-p (data)
  "Non-nil if DATA is a semantic (three-tier) theme, not the flat form.
Discriminated by a `:palette' key (the flat form uses `:defs')."
  (and (hash-table-p data) (gethash :palette data)))

(defun ck/doom-theme--kw-name (k)
  "Return the bare name string of keyword-or-symbol K (no leading colon)."
  (if (keywordp k) (substring (symbol-name k) 1) (format "%s" k)))

(defun ck/doom-theme--name-set (&rest maps)
  "Return a hash-set (name-string -> t) of the keys of MAPS (hash-tables)."
  (let ((s (make-hash-table :test 'equal)))
    (dolist (m maps)
      (when (hash-table-p m)
        (maphash (lambda (k _) (puthash (ck/doom-theme--kw-name k) t s)) m)))
    s))

(defconst ck/doom-theme--ops
  '((:lighten . doom-lighten) (:darken . doom-darken))
  "Color operations the symbol-free EDN grammar allows: op-keyword -> elisp fn.
These are the ONLY operations; a vector headed by one is compiled into the
corresponding call.  Extend deliberately -- the grammar is closed on purpose.")

(defun ck/doom-theme--as-name (x)
  "Coerce a theme name X (a string in the EDN, or already a symbol) to a symbol."
  (if (stringp x) (intern x) x))

(defun ck/doom-theme--xlate (x tokens toggles name)
  "Translate a symbol-free EDN datum X into an elisp theme form.
The EDN files are pure data with NO symbols; this maps that data onto the
elisp a `def-doom-theme' body expects:

  - a keyword naming a TOKENS entry (a :palette or :roles name) -> that bare
    symbol, so doom's colorizer resolves it to a color;
  - any other keyword -> a quoted literal symbol (:bold -> \\='bold, :wave ->
    \\='wave, :unspecified -> \\='unspecified, an :inherit face name, ...);
  - a vector headed by :lighten or :darken -> the matching (doom-lighten ...)
    / (doom-darken ...) call, arguments translated recursively (nestable);
  - any other vector -> a quoted list (a [gui term256 term16] color triple);
  - a map used as a value -> an elisp plist, so an :underline/:box spec like
    {:style :wave :color :red} becomes (list :style \\='wave :color red);
  - numbers, strings, and t/nil (from EDN true/false/nil) pass through.

TOKENS is a hash-set of palette+role name strings.  NAME and TOGGLES are kept
for signature compatibility; TOGGLES is empty now that themes carry none."
  (cond
   ((keywordp x)
    (let ((n (substring (symbol-name x) 1)))
      (cond ((gethash n tokens) (intern n))
            ((and toggles (gethash n toggles))
             (intern (format "%s-%s" name n)))
            (t (list 'quote (intern n))))))
   ((vectorp x)
    (let* ((lst (append x nil))
           (op  (and lst (keywordp (car lst))
                     (cdr (assq (car lst) ck/doom-theme--ops)))))
      (if op
          (cons op (mapcar (lambda (e) (ck/doom-theme--xlate e tokens toggles name))
                           (cdr lst)))
        (list 'quote (mapcar (lambda (e) (ck/doom-theme--xlate e tokens toggles name))
                             lst)))))
   ((hash-table-p x)
    (let (plist)
      (maphash (lambda (k v)
                 (setq plist (nconc plist
                                    (list k (ck/doom-theme--xlate v tokens toggles name)))))
               x)
      (cons 'list plist)))
   (t x)))

(defun ck/doom-theme--compile-defs (map tokens toggles name)
  "Compile a MAP of {:name expr} into a let-binding list ((sym form) ...).
Insertion order is preserved."
  (let (acc)
    (when (hash-table-p map)
      (maphash (lambda (k v)
                 (push (list (intern (ck/doom-theme--kw-name k))
                             (ck/doom-theme--xlate v tokens toggles name))
                       acc))
               map))
    (nreverse acc)))

(defun ck/doom-theme--face-form (fkey spec tokens toggles name)
  "Compile face key FKEY + SPEC map into a `def-doom-theme' face-spec form.
`:&override t' in SPEC yields the doom `(FACE &override)' head; the remaining
entries become the property plist in insertion order."
  (let* ((fsym (intern (ck/doom-theme--kw-name fkey)))
         (override (and (hash-table-p spec) (gethash :&override spec)))
         (head (if override (list fsym '&override) fsym))
         plist)
    (when (hash-table-p spec)
      (maphash (lambda (k v)
                 (unless (eq k :&override)
                   (setq plist (nconc plist
                                      (list k (ck/doom-theme--xlate v tokens toggles name))))))
               spec))
    (cons head plist)))

(defun ck/doom-theme--faces-of (map tokens toggles name)
  "Compile a :faces MAP of {:face spec} into a list of face-spec forms."
  (let (acc)
    (when (hash-table-p map)
      (maphash (lambda (fk spec)
                 (push (ck/doom-theme--face-form fk spec tokens toggles name) acc))
               map))
    (nreverse acc)))

(defun ck/doom-theme--family-faces (families tokens toggles name)
  "Expand the FAMILIES shorthand map into a list of face-spec forms.
  :rainbow VEC -> (rainbow-delimiters-depth-N-face :foreground VEC[N-1])
  :outline VEC -> ((outline-N &override) :foreground VEC[N-1])
Each VEC element is a color keyword, resolved via TOKENS."
  (let (acc)
    (when (hash-table-p families)
      (let ((rainbow (gethash :rainbow families))
            (outline (gethash :outline families))
            (i 1))
        (when rainbow
          (setq i 1)
          (dolist (c (append rainbow nil))
            (push (list (intern (format "rainbow-delimiters-depth-%d-face" i))
                        :foreground (ck/doom-theme--xlate c tokens toggles name))
                  acc)
            (setq i (1+ i))))
        (when outline
          (setq i 1)
          (dolist (c (append outline nil))
            (push (list (list (intern (format "outline-%d" i)) '&override)
                        :foreground (ck/doom-theme--xlate c tokens toggles name))
                  acc)
            (setq i (1+ i))))))
    (nreverse acc)))

(defun ck/doom-theme--structural-data (data)
  "Return the parsed `:extends' structural EDN for DATA, or nil.
The extends name is resolved as <name>.edn in `ck/doom-theme-dir'."
  (let ((ext (gethash :extends data)))
    (when (and ext (not (string-empty-p (string-trim (format "%s" ext)))))
      (ck/doom-theme--read-edn
       (expand-file-name (concat (format "%s" ext) ".edn") ck/doom-theme-dir)))))

(defun ck/doom-theme--compile (data)
  "Compile semantic three-tier DATA into a plist (:name :toggles :form).
Merges the `:extends' structural layer's faces UNDER the theme's own and
resolves every token/toggle keyword; `:form' is a ready-to-eval
`def-doom-theme'.  The token set is the theme's own :palette + :roles keys, so
the structural layer's role references resolve against this theme."
  (let* ((name    (ck/doom-theme--as-name (gethash :name data)))
         (struct  (ck/doom-theme--structural-data data))
         (tokens  (ck/doom-theme--name-set (gethash :palette data)
                                           (gethash :roles data)))
         (toggles (ck/doom-theme--name-set (gethash :toggles data)))
         (defs    (append (ck/doom-theme--compile-defs (gethash :palette data) tokens toggles name)
                          (ck/doom-theme--compile-defs (gethash :roles data) tokens toggles name)))
         (faces   (append (ck/doom-theme--faces-of (and struct (gethash :faces struct)) tokens toggles name)
                          (ck/doom-theme--family-faces (gethash :families data) tokens toggles name)
                          (ck/doom-theme--faces-of (gethash :faces data) tokens toggles name)))
         (vars    (ck/doom-theme--compile-defs (gethash :vars data) tokens toggles name)))
    (list :name name
          :toggles (gethash :toggles data)
          :form (ck/doom-theme--assemble name (gethash :doc data) defs faces vars))))

(defun ck/doom-theme--post-apply ()
  "Re-assert the non-theme face tweaks after (re)enabling the theme.
Mirrors the fixups in `ck/set-theme' (config/theme.el): a non-bold, no-inherit
function-name face and the configured default height."
  (set-face-attribute 'font-lock-function-name-face nil
                      :weight 'normal :inherit nil)
  (when (boundp 'normal-font-height)
    (set-face-attribute 'default nil :height (symbol-value 'normal-font-height))))

(defun ck/doom-theme--apply-form (name toggles form)
  "Define NAME's TOGGLES defcustoms, eval theme FORM, enable, and fix up.
The shared tail of both apply paths; returns NAME."
  (dolist (tf (ck/doom-theme--build-toggles name toggles))
    (eval tf t))
  (eval form t)
  (enable-theme name)
  (ck/doom-theme--post-apply)
  name)

(defun ck/doom-theme-apply-data (data)
  "Build, define, and enable the doom theme described by parsed EDN DATA.
DATA is the top-level hash-table, in either the semantic three-tier form
(`:palette'/`:roles'/`:families', compiled here) or the flat classic form.
Re-evaluates the whole theme, so derived colors recompute and every base face
rebuilds; safe to call repeatedly (the live-edit path).  Returns the theme name
(a symbol)."
  (require 'doom-themes)
  (if (ck/doom-theme--semantic-p data)
      (let ((c (ck/doom-theme--compile data)))
        (ck/doom-theme--apply-form (plist-get c :name)
                                   (plist-get c :toggles)
                                   (plist-get c :form)))
    (ck/doom-theme--apply-form (gethash :name data)
                               (gethash :toggles data)
                               (ck/doom-theme--build-form data))))

(defun ck/doom-theme-apply-string (string)
  "Parse EDN STRING and apply it as the active doom theme.
The live-edit path: applied from unsaved buffer text, so a half-typed,
not-yet-valid EDN simply signals and is skipped by the caller."
  (ck/doom-theme-apply-data (ck/doom-theme--parse string)))

(defun ck/doom-theme-load-edn (file)
  "Build, define, and enable the doom theme described by EDN FILE.
Returns the theme name (a symbol)."
  (ck/doom-theme-apply-data (ck/doom-theme--read-edn file)))

(defun ck/doom-theme-reload ()
  "Reload and re-apply the theme from `ck/doom-theme-edn-file'."
  (interactive)
  (ck/doom-theme-load-edn ck/doom-theme-edn-file))

;;; Gallery preview buffer ---------------------------------------------------
;;
;; A read-only canvas that renders the faces a theme touches -- syntax classes,
;; UI chrome, diagnostics, VC/diff, org, rainbow-delimiters -- so a look can be
;; judged at a glance.  It is drawn with explicit `face' text properties (not
;; live font-lock), so it is deterministic and mode-independent; when the theme
;; re-applies, every face changes globally and this buffer restyles for free
;; (no rebuild needed per edit).  `display-line-numbers' and `hl-line-mode'
;; bring in the line-number and hl-line faces; the window's own mode-line shows
;; `mode-line' / `mode-line-inactive'.

(defvar ck/doom-theme-gallery-buffer "*doom-theme-gallery*"
  "Name of the theme preview buffer.")

(defun ck/doom-theme--f (&rest faces)
  "Return the first defined face among FACES, else `default'.
Keeps the gallery robust when an optional package's faces (clojure-mode,
rainbow-delimiters, flycheck, org) are not loaded in this session; pass a
mode-specific face first and a stock font-lock fallback second."
  (or (seq-find #'facep faces) 'default))

(defun ck/doom-theme--seg (text &rest faces)
  "Return TEXT propertized with the first defined face among FACES."
  (propertize text 'face (apply #'ck/doom-theme--f faces)))

(defun ck/doom-theme--fontify (code mode &rest minor-modes)
  "Return CODE fontified as MODE would render it, carrying `face' properties.
Runs real font-lock in a throwaway MODE buffer, so tokens get exactly the faces
they get in a live buffer (e.g. a Clojure ns name is `font-lock-type-face', not
default).  Any MINOR-MODES that are `fboundp' are enabled first, so e.g.
rainbow-delimiters colors the parens too.  Mode hooks are skipped, so this stays
fast and free of side effects (no lsp/cider/flycheck attaching to a temp
buffer); the trade-off is that it shows static fontification, not the extra
symbol highlighting a live REPL connection would add."
  (with-temp-buffer
    (insert code)
    (delay-mode-hooks (funcall mode))
    (dolist (m minor-modes)
      (when (fboundp m) (funcall m 1)))
    (font-lock-ensure)
    (buffer-string)))

(defconst ck/doom-theme--clojure-sample
  "(ns app.core
  (:require [clojure.string :as str]))

;; greet someone by name
(defn greet
  \"Say hello to NAME.\"
  [name]
  (let [msg (str \"Hello, \" name \"!\")]
    (println msg)
    {:greeting msg :count 42}))

(def people #{:alice :bob :carol})

(defrecord Point [x y])

(comment
  (map inc [1 2 3])
  (greet \"world\"))"
  "Representative Clojure used to preview code faces in the gallery.")

(defun ck/doom-theme--gallery-content (name)
  "Insert the gallery preview body for theme NAME into the current buffer."
  (insert (ck/doom-theme--seg (format "Doom Theme Gallery  -  %s\n" name)
                              'mode-line-emphasis)
          "\n")
  ;; code sample -- fontified by REAL clojure-mode (+ rainbow-delimiters when
  ;; available), so every token gets exactly the face it gets in a live Clojure
  ;; buffer instead of a hand-guessed one.
  (insert (ck/doom-theme--seg ";;; clojure\n" 'font-lock-comment-face))
  (if (fboundp 'clojure-mode)
      (insert (ck/doom-theme--fontify ck/doom-theme--clojure-sample
                                      'clojure-mode 'rainbow-delimiters-mode))
    (insert ck/doom-theme--clojure-sample))
  (insert "\n\n")
  ;; ui chrome
  (insert (ck/doom-theme--seg ";;; ui\n" 'font-lock-comment-face))
  (insert "region:    " (ck/doom-theme--seg " selected text " 'region) "\n")
  (insert "highlight: " (ck/doom-theme--seg " highlighted " 'highlight) "\n")
  (insert "isearch:   " (ck/doom-theme--seg " found " 'isearch)
          "   lazy: " (ck/doom-theme--seg " other " 'lazy-highlight) "\n\n")
  ;; diagnostics
  (insert (ck/doom-theme--seg ";;; diagnostics\n" 'font-lock-comment-face))
  (insert "error:   " (ck/doom-theme--seg "undefined-var" 'flycheck-error) "\n")
  (insert "warning: " (ck/doom-theme--seg "unused binding" 'flycheck-warning) "\n")
  (insert "info:    " (ck/doom-theme--seg "consider refactor" 'flycheck-info) "\n\n")
  ;; version control / diff
  (insert (ck/doom-theme--seg ";;; version control\n" 'font-lock-comment-face))
  (insert (ck/doom-theme--seg "+ added line of code" 'diff-added) "\n")
  (insert (ck/doom-theme--seg "- removed line of code" 'diff-removed) "\n")
  (insert (ck/doom-theme--seg "~ modified line of code" 'diff-changed) "\n\n")
  ;; org
  (insert (ck/doom-theme--seg ";;; org\n" 'font-lock-comment-face))
  (insert (ck/doom-theme--seg "* Top heading" 'outline-1) "\n")
  (insert (ck/doom-theme--seg "** Sub heading" 'outline-2) "\n")
  (insert (ck/doom-theme--seg "TODO" 'org-todo) " write more themes  "
          (ck/doom-theme--seg ":emacs:" 'org-tag) "\n")
  (insert (ck/doom-theme--seg "> a quoted paragraph" 'org-quote) "\n\n")
  ;; rainbow delimiters
  (insert (ck/doom-theme--seg ";;; rainbow-delimiters\n" 'font-lock-comment-face))
  (dotimes (i 7)
    (insert (ck/doom-theme--seg "(" (intern (format "rainbow-delimiters-depth-%d-face" (1+ i))))))
  (insert " nest ")
  (dotimes (i 7)
    (insert (ck/doom-theme--seg ")" (intern (format "rainbow-delimiters-depth-%d-face" (- 7 i))))))
  (insert "\n"))

(defun ck/doom-theme--build-gallery (name)
  "(Re)build the gallery buffer for theme NAME and return it."
  (with-current-buffer (get-buffer-create ck/doom-theme-gallery-buffer)
    (special-mode)
    (setq-local display-line-numbers t)
    (hl-line-mode 1)
    (let ((inhibit-read-only t))
      (erase-buffer)
      (ck/doom-theme--gallery-content name)
      (goto-char (point-min)))
    (current-buffer)))

(defun ck/doom-theme--show-gallery (name)
  "Build the gallery for NAME and display it, returning its window."
  (let ((buf (ck/doom-theme--build-gallery name)))
    (display-buffer buf)))

(defun ck/doom-theme--kill-gallery ()
  "Delete the gallery's windows and kill its buffer, if present."
  (when-let* ((buf (get-buffer ck/doom-theme-gallery-buffer)))
    (dolist (win (get-buffer-window-list buf nil t))
      (when (window-live-p win)
        (ignore-errors (delete-window win))))
    (kill-buffer buf)))

;;; Live edit session --------------------------------------------------------
;;
;; `ck/doom-theme-edit' opens an EDN theme in a buffer running
;; `ck/doom-theme-edit-mode', which re-applies the theme (debounced) on every
;; buffer change -- so edits show up live -- and also installs a filenotify
;; watch on the file, so an external writer (e.g. a future browser editor)
;; applies too.  The watch is reload-safe: a single global descriptor is
;; removed before any new one is added, and removed again on teardown.

(defgroup ck/doom-theme nil
  "Live editing of EDN-sourced doom themes."
  :group 'cmacs)

(defcustom ck/doom-theme-apply-debounce 0.075
  "Seconds to wait after a change before re-applying the theme."
  :type 'number
  :group 'ck/doom-theme)

(defvar ck/doom-theme-dir
  (expand-file-name "config/theme" cmacs-config-path)
  "Directory holding EDN doom-theme sources.")

(defcustom ck/doom-theme-template-file
  (expand-file-name "config/theme/doom-molokam.edn" cmacs-config-path)
  "EDN theme copied as the starting point for a new theme."
  :type 'file
  :group 'ck/doom-theme)

(defvar ck/doom-theme-template-name "doom-molokam"
  "Theme-name token in `ck/doom-theme-template-file' replaced when copying.
Every occurrence (the `:name', the toggle-variable prefixes, comments) is
substituted with the new theme's name.")

(defvar ck/doom-theme--edit-buffer nil
  "The buffer currently running a live edit session, or nil.")

(defvar ck/doom-theme--edit-file nil
  "Absolute path of the EDN file the active session watches, or nil.")

(defvar ck/doom-theme--opened-buffer nil
  "The EDN buffer this session opened itself, or nil if it was already open.
Closed on teardown so `finish' leaves no buffers behind that the user did not
open; a pre-existing buffer is left untouched.")

(defvar ck/doom-theme--window-config nil
  "Window configuration captured when a fresh session started.
Restored by `finish' so the frame returns to its pre-session layout.  Captured
only on a fresh start (not on a theme switch), so it stays the true original.")

(defvar ck/doom-theme--watch nil
  "Active filenotify descriptor for the edit session, or nil.")

(defvar ck/doom-theme--apply-timer nil
  "Pending debounced re-apply timer, or nil.")

(defun ck/doom-theme--schedule (thunk &optional quiet)
  "Run THUNK after `ck/doom-theme-apply-debounce', collapsing rapid calls.
Errors are caught; reported via `message' unless QUIET (the live buffer path,
where transient parse errors on half-typed EDN are expected and ignored)."
  (when (timerp ck/doom-theme--apply-timer)
    (cancel-timer ck/doom-theme--apply-timer))
  (setq ck/doom-theme--apply-timer
        (run-with-timer
         ck/doom-theme-apply-debounce nil
         (lambda ()
           (setq ck/doom-theme--apply-timer nil)
           (condition-case err
               (funcall thunk)
             (error (unless quiet
                      (message "doom-theme: %s" (error-message-string err)))))))))

(defun ck/doom-theme--after-change (&rest _)
  "Buffer-change hook: schedule a live re-apply from this buffer's text."
  (let ((buf (current-buffer)))
    (ck/doom-theme--schedule
     (lambda ()
       (when (buffer-live-p buf)
         (ck/doom-theme-apply-string (with-current-buffer buf (buffer-string)))))
     t)))

(defun ck/doom-theme--on-file-event (event)
  "Filenotify handler: re-apply from disk when the watched file changes.
Re-arms the watch afterwards, since some save styles replace the inode."
  (let ((action (nth 1 event)))
    (when (memq action '(changed created renamed attribute-changed))
      (ck/doom-theme--schedule
       (lambda ()
         (when (and ck/doom-theme--edit-file
                    (file-exists-p ck/doom-theme--edit-file))
           (ck/doom-theme-load-edn ck/doom-theme--edit-file)
           (ck/doom-theme--start-watch ck/doom-theme--edit-file)))))))

(defun ck/doom-theme--stop-watch ()
  "Remove the active filenotify watch, if any."
  (when ck/doom-theme--watch
    (ignore-errors (file-notify-rm-watch ck/doom-theme--watch))
    (setq ck/doom-theme--watch nil)))

(defun ck/doom-theme--start-watch (file)
  "Watch FILE for changes, replacing any prior watch (reload-safe)."
  (require 'filenotify)
  (ck/doom-theme--stop-watch)
  (setq ck/doom-theme--watch
        (file-notify-add-watch file '(change) #'ck/doom-theme--on-file-event)))

(define-minor-mode ck/doom-theme-edit-mode
  "Live-edit the doom theme in this EDN buffer.
While on, buffer changes re-apply the theme to the running Emacs (debounced by
`ck/doom-theme-apply-debounce'), and a filenotify watch re-applies external
writes to the file.  Turn off (or run `ck/doom-theme-edit-finish') to tear the
watch and timer down and continue as normal; whatever look is applied stays."
  :lighter " ThemeEdit"
  :keymap (let ((m (make-sparse-keymap)))
            (define-key m (kbd "C-c C-c") #'ck/doom-theme-edit-finish)
            (define-key m (kbd "C-c C-o") #'ck/doom-theme-edit)
            m)
  (if ck/doom-theme-edit-mode
      (let ((file (buffer-file-name)))
        (unless file
          (setq ck/doom-theme-edit-mode nil)
          (user-error "This buffer is not visiting an EDN file"))
        (setq ck/doom-theme--edit-buffer (current-buffer)
              ck/doom-theme--edit-file file
              ck/doom-theme--opened-buffer nil)
        (ck/doom-theme--start-watch file)
        (add-hook 'after-change-functions #'ck/doom-theme--after-change nil t)
        (let ((name (ck/doom-theme-apply-string (buffer-string))))
          (ck/doom-theme--show-gallery name)))
    (remove-hook 'after-change-functions #'ck/doom-theme--after-change t)
    (ck/doom-theme--stop-watch)
    (when (timerp ck/doom-theme--apply-timer)
      (cancel-timer ck/doom-theme--apply-timer)
      (setq ck/doom-theme--apply-timer nil))
    (when (eq ck/doom-theme--edit-buffer (current-buffer))
      (setq ck/doom-theme--edit-buffer nil
            ck/doom-theme--edit-file nil))))

(defun ck/doom-theme--finish-active ()
  "Tear down any active edit session (in whatever buffer holds it).
If the session opened the EDN buffer itself, kill that buffer too."
  (let ((opened ck/doom-theme--opened-buffer))
    (when (buffer-live-p ck/doom-theme--edit-buffer)
      (with-current-buffer ck/doom-theme--edit-buffer
        (when ck/doom-theme-edit-mode
          (ck/doom-theme-edit-mode -1))))
    (setq ck/doom-theme--edit-buffer nil
          ck/doom-theme--edit-file nil
          ck/doom-theme--opened-buffer nil)
    (when (buffer-live-p opened)
      (kill-buffer opened))))

(defun ck/doom-theme-edit-finish ()
  "End the live theme-edit session and continue as normal.
Tears down the watch/timer and closes the gallery preview.  The last-applied
look stays and the EDN buffer is left open; save it to persist the look."
  (interactive)
  (let ((buf ck/doom-theme--edit-buffer)
        (wc  ck/doom-theme--window-config))
    (ck/doom-theme--finish-active)
    (ck/doom-theme--kill-gallery)
    (when wc
      (ignore-errors (set-window-configuration wc)))
    (setq ck/doom-theme--window-config nil)
    (message "doom-theme edit session ended%s."
             (if (and (buffer-live-p buf)
                      (buffer-modified-p buf))
                 " (EDN buffer has unsaved changes)"
               ""))))

(defun ck/doom-theme--theme-files ()
  "Return the EDN theme files in `ck/doom-theme-dir' (skipping lock/temp)."
  (directory-files ck/doom-theme-dir t "\\`[^.#].*\\.edn\\'"))

(defun ck/doom-theme--theme-names ()
  "Return the base names of the EDN themes in `ck/doom-theme-dir'."
  (mapcar #'file-name-base (ck/doom-theme--theme-files)))

(defun ck/doom-theme--new-from-template (name)
  "Create <NAME>.edn in `ck/doom-theme-dir' from the template, return its path.
Substitutes the template's theme-name token with NAME throughout."
  (let ((file (expand-file-name (concat name ".edn") ck/doom-theme-dir))
        (tmpl (with-temp-buffer
                (insert-file-contents ck/doom-theme-template-file)
                (buffer-string))))
    (when (file-exists-p file)
      (user-error "Theme file already exists: %s" file))
    (with-temp-file file
      (insert (replace-regexp-in-string
               (regexp-quote ck/doom-theme-template-name) name tmpl t t)))
    file))

(defun ck/doom-theme-edit (&optional selection)
  "Start (or switch) a live doom-theme editing session.
Prompts for an existing EDN theme by name; an empty selection creates a new
theme from `ck/doom-theme-template-file'.  Opens the theme's EDN in a live
`ck/doom-theme-edit-mode' buffer and pops the gallery preview, so edits restyle
the running Emacs in real time.  Re-running (also `C-c C-o' in the buffer)
tears down the current session and switches to the chosen theme."
  (interactive)
  ;; Capture the pre-session layout only on a fresh start; a switch keeps the
  ;; original so `finish' still returns to where the user began.
  (when (not (buffer-live-p ck/doom-theme--edit-buffer))
    (setq ck/doom-theme--window-config (current-window-configuration)))
  (ck/doom-theme--finish-active)
  (let* ((names (ck/doom-theme--theme-names))
         (sel (or selection
                  (completing-read
                   "Edit doom theme (empty = new from template): "
                   names nil nil)))
         (file (if (member sel names)
                   (expand-file-name (concat sel ".edn") ck/doom-theme-dir)
                 (ck/doom-theme--new-from-template
                  (if (string-empty-p (string-trim sel))
                      (read-string "New theme name: " "doom-")
                    sel)))))
    (let ((pre (get-file-buffer file)))
      (find-file file)
      (ck/doom-theme-edit-mode 1)
      (setq ck/doom-theme--opened-buffer (unless pre (current-buffer))))))

(provide 'config/theme/editor)
