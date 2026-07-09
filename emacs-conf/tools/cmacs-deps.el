;;; cmacs-deps.el --- explicit-dependency tooling for the cmacs config -*- lexical-binding: t; -*-
;;
;; Loaded into the LIVE WM Emacs, which alone knows `symbol-file'/`macrop' for
;; every config + package symbol.  The whole pipeline runs here in the server;
;; the only subprocess is an independent `emacs -Q --batch' byte-compile (it
;; never talks back to the server, so there is no re-entrancy deadlock).
;;
;; What it does, per file:
;;   1. byte-compile a copy in a clean emacs -Q with this session's load-path
;;      (reproducing flycheck's `emacs-lisp' checker) to list undefined symbols;
;;   2. resolve each symbol via `symbol-file'/`macrop';
;;   3. emit a dependency header and (optionally) splice it in, then re-check.
;;
;; Header policy (see .eca/docs/plans/module-dependency-refactor.md):
;;   - `(require 'prelude)' first: it owns the `declare-*' macros + dash.
;;   - a MACRO provider must be `require'd (the compiler needs it to expand);
;;     found by fixpoint (adding a require can reveal a nested macro).
;;   - everything else is forward-declared (`declare-functions'/`declare-vars'),
;;     which never force-loads, so deferred packages stay deferred (decision
;;     0001) and no load cycle is introduced.  Promoting a genuine load-time
;;     sibling function from declare to `require' is a deliberate human step.

(require 'prelude)
(require 'subr-x)
(require 'cl-lib)

(defvar cmacs-deps-root
  (expand-file-name "~/projects/Camsbury/config/emacs-conf/")
  "Absolute path to emacs-conf/, used to tell config siblings from packages.")

(defvar cmacs-deps--lp-cache nil
  "Cached temp file holding this session's `load-path' as a setq form.")

(defun cmacs-deps--lp ()
  "Path to a temp .el that sets `load-path' to this session's value."
  (unless (and cmacs-deps--lp-cache (file-exists-p cmacs-deps--lp-cache))
    (setq cmacs-deps--lp-cache (make-temp-file "cmacs-lp" nil ".el"))
    (with-temp-file cmacs-deps--lp-cache
      (prin1 `(setq load-path ',load-path) (current-buffer))))
  cmacs-deps--lp-cache)

;;;; --- resolution ---------------------------------------------------------

(defun cmacs-deps--src (path)
  "Normalize PATH (possibly .elc) to its .el source when that exists."
  (when path
    (let ((s (replace-regexp-in-string "\\.elc\\'" ".el" path)))
      (if (file-exists-p s) s path))))

(defun cmacs-deps--feature-of (path)
  "Config feature name for PATH under `cmacs-deps-root', else nil.
E.g. .../emacs-conf/lib/utils.el -> \"lib/utils\"."
  (when (and path (string-prefix-p cmacs-deps-root (expand-file-name path)))
    (file-name-sans-extension
     (file-relative-name (expand-file-name path) cmacs-deps-root))))

(defun cmacs-deps-resolve (name kind)
  "Resolve symbol NAME (string). KIND is `function' or `variable'.
Plist: :name :macro :sibling (feature or nil) :library (or nil) :file :unknown."
  (let* ((sym (intern name))
         (path (cmacs-deps--src
                (ignore-errors
                  (symbol-file sym (if (eq kind 'variable) 'defvar 'defun)))))
         (feature (cmacs-deps--feature-of path)))
    (list :name name
          :macro (and (eq kind 'function) (fboundp sym) (macrop sym))
          :sibling feature
          :library (and path (not feature) (file-name-base path))
          :file (or feature (and path (file-name-base path)))
          :unknown (null path))))

;;;; --- compile + parse ----------------------------------------------------

(defun cmacs-deps--compile (file &optional extra-requires)
  "Byte-compile a copy of FILE in a clean `emacs -Q'; return a plist.
Each feature in EXTRA-REQUIRES is `require'd after the line-1 lexical-binding
cookie; the copy is compiled with this session's load-path.

Plist keys:
  :text  the raw warning/error output (stderr+stdout);
  :ok    non-nil iff the byte-compile ran to completion (a .elc appeared and
         no `Error:' line was emitted).  A require that aborts compilation
         (e.g. requiring a side-effectful hub in a bare probe) leaves :ok nil,
         which is how we tell a genuine clean compile from an aborted one -
         both otherwise show zero warnings."
  (let* ((lp (cmacs-deps--lp))
         (dir (make-temp-file "cmacs-fc" t))
         (copy (expand-file-name (file-name-nondirectory file) dir))
         (elc (concat copy "c")))
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char (point-min))
      (forward-line 1)
      (dolist (r extra-requires) (insert (format "(require '%s)\n" r)))
      (write-region (point-min) (point-max) copy nil 'silent))
    (let* ((text (with-temp-buffer
                   (call-process
                    "sh" nil t nil "-c"
                    (format "emacs -Q --batch --load %s --eval '(setq byte-compile-warnings t)' -f batch-byte-compile %s 2>&1"
                            (shell-quote-argument lp) (shell-quote-argument copy)))
                   (buffer-string)))
           (ok (and (file-exists-p elc)
                    (not (string-match-p "^[^\n]*\\bError:" text)))))
      (delete-directory dir t)
      (list :text text :ok ok))))

(defun cmacs-deps--compile-warnings (file &optional extra-requires)
  "Return just the byte-compiler warning/error text for FILE.
Thin wrapper over `cmacs-deps--compile' for callers that ignore :ok."
  (plist-get (cmacs-deps--compile file extra-requires) :text))

(defun cmacs-deps--between-quotes (line)
  "Return the symbol name inside the curly quotes of LINE, or nil."
  (when (string-match "[\u2018']\\([^\u2019']+\\)[\u2019']" line)
    (match-string 1 line)))

(defun cmacs-deps--parse (warnings)
  "Parse WARNINGS text into (FUNCTION-NAMES . VARIABLE-NAMES), both deduped.
Ignores docstring warnings (out of scope for the dependency refactor)."
  (let ((fns '()) (vars '()))
    (dolist (line (split-string warnings "\n" t))
      (cond
       ((string-match-p "docstring" line) nil)
       ((string-match-p "\\(is not known to be defined\\|might not be defined at runtime\\)" line)
        (when-let ((s (cmacs-deps--between-quotes line))) (push s fns)))
       ((string-match-p "reference to free variable" line)
        (when-let ((s (cmacs-deps--between-quotes line))) (push s vars)))))
    (cons (sort (delete-dups fns) #'string<)
          (sort (delete-dups vars) #'string<))))

;;;; --- header generation --------------------------------------------------

(defun cmacs-deps--macro-requires (fns)
  "Return the set of features/libraries to `require' for the macros in FNS.
Excludes dash/prelude (covered by the prelude require)."
  (let ((reqs '()))
    (dolist (n fns)
      (let ((r (cmacs-deps-resolve n 'function)))
        (when (and (plist-get r :macro) (plist-get r :file)
                   (not (member (plist-get r :file) '("dash" "prelude"))))
          (cl-pushnew (plist-get r :file) reqs :test #'equal))))
    (sort reqs #'string<)))

(defun cmacs-deps-analyze (file)
  "Return a plist describing FILE's dependency needs.
:requires (safe macro providers) :decls (alist file -> fn names) :vars
:unknown :siblings (feature deps) :unsafe-requires :probe-error

The fixpoint adds macro-provider `require's one at a time, but only after a
probe confirms the require does NOT abort compilation.  A provider that
aborts the probe (a side-effectful hub like `core/bindings', or a macro
generated at runtime like evil/general's `nmap') is quarantined in
:unsafe-requires and NOT added - so its macros surface as honest residual
warnings instead of a false clean.  Presence of :unsafe-requires or a
:probe-error means this file needs a human (usually it is a hub that should
get `(not unresolved)' suppression, not an explicit header)."
  (let ((reqs '()) (unsafe '()) (probe-error nil) fns vars)
    ;; Base probe: prelude only.  If this already aborts, the file itself
    ;; errors under a clean compile - flag it, do not trust any residual.
    (unless (plist-get (cmacs-deps--compile file '(prelude)) :ok)
      (setq probe-error t))
    ;; Fixpoint: adding a macro require can reveal further macros.  Each new
    ;; candidate is probed on its own before being committed.
    (let ((changed t))
      (while changed
        (setq changed nil)
        (let* ((w (cmacs-deps--compile-warnings file (cons 'prelude reqs)))
               (cands (cmacs-deps--macro-requires (car (cmacs-deps--parse w)))))
          (dolist (m cands)
            (unless (or (member m reqs) (member m unsafe))
              (setq changed t)
              (if (plist-get (cmacs-deps--compile file (cons 'prelude (cons m reqs))) :ok)
                  (push m reqs)
                (push m unsafe)))))))
    (let* ((w (cmacs-deps--compile-warnings file (cons 'prelude reqs)))
           (pv (cmacs-deps--parse w))
           (decls (make-hash-table :test 'equal))
           (unknown '()) (unknown-vars '()) (known-vars '()) (siblings '()))
      (setq fns (car pv) vars (cdr pv))
      (dolist (n fns)
        (let ((r (cmacs-deps-resolve n 'function)))
          (cond ((plist-get r :unknown) (push n unknown))
                (t (let ((f (plist-get r :file)))
                     (puthash f (cons n (gethash f decls)) decls)
                     (when (plist-get r :sibling)
                       (cl-pushnew (plist-get r :sibling) siblings :test #'equal)))))))
      ;; A "free variable" warning is only safe to auto-`declare-vars' when it
      ;; names a REAL global (`symbol-file' resolves it).  An unresolved one is
      ;; almost always a local the compiler mis-parsed because a macro did not
      ;; expand (e.g. a `letrec'/`cl-letf' binding); emitting `(defvar NAME)'
      ;; for it would wrongly make that name dynamically scoped session-wide.
      ;; Route those to manual review instead.
      (dolist (v vars)
        (if (plist-get (cmacs-deps-resolve v 'variable) :unknown)
            (push v unknown-vars)
          (push v known-vars)))
      (dolist (m reqs)
        (when (cmacs-deps--feature-of (concat cmacs-deps-root m ".el"))
          (cl-pushnew m siblings :test #'equal)))
      (list :requires (sort reqs #'string<)
            :decls (let (a) (maphash (lambda (k v)
                                       (push (cons k (sort (delete-dups v) #'string<)) a))
                                     decls)
                     (sort a (lambda (x y) (string< (car x) (car y)))))
            :vars (sort known-vars #'string<)
            :unknown (sort unknown #'string<)
            :unknown-vars (sort unknown-vars #'string<)
            :siblings (sort siblings #'string<)
            :unsafe-requires (sort unsafe #'string<)
            :probe-error probe-error))))

(defun cmacs-deps-header (file)
  "Return the proposed dependency-header string for FILE.
When the analysis hit a hub/side-effect require it could not safely add
(:unsafe-requires) or the base file will not compile clean (:probe-error),
the header is prefixed with a MANUAL banner instead of being trusted."
  (let* ((a (cmacs-deps-analyze file))
         (lines (list "(require 'prelude)")))
    (when (plist-get a :probe-error)
      (push ";; MANUAL: file does not byte-compile clean under prelude alone;" lines)
      (push ";;         residual warnings below are unreliable - inspect by hand." lines))
    (when (plist-get a :unsafe-requires)
      (push (format ";; MANUAL: macro provider(s) %s abort a clean probe (hub or"
                    (mapconcat #'identity (plist-get a :unsafe-requires) " ")) lines)
      (push ";;         runtime-generated macro); likely a HUB - suppress with" lines)
      (push ";;         `byte-compile-warnings: (not unresolved)', not a header." lines))
    (dolist (r (plist-get a :requires))
      (push (format "(require '%s)" r) lines))
    (setq lines (nreverse lines))
    (dolist (cell (plist-get a :decls))
      (let ((names (cdr cell)))
        (setq lines
              (append lines
                      (list (if (= (length names) 1)
                                (format "(declare-functions \"%s\" %s)" (car cell) (car names))
                              (format "(declare-functions \"%s\"\n  %s)"
                                      (car cell) (mapconcat #'identity names "\n  "))))))))
    (when (plist-get a :vars)
      (setq lines (append lines (list (format "(declare-vars %s)"
                                              (mapconcat #'identity (plist-get a :vars) " "))))))
    (when (plist-get a :unknown)
      (setq lines (append lines (list (format ";; UNRESOLVED fns (declare by hand): %s"
                                              (mapconcat #'identity (plist-get a :unknown) " "))))))
    (when (plist-get a :unknown-vars)
      (setq lines (append lines
                          (list (format ";; UNRESOLVED vars (usually a local a macro mis-parsed;")
                                (format ";;   do NOT declare-vars unless it is a real global): %s"
                                        (mapconcat #'identity (plist-get a :unknown-vars) " "))))))
    (mapconcat #'identity lines "\n")))

;;;; --- library vs application classification ------------------------------

(defconst cmacs-deps--definitional-heads
  '(defun cl-defun defun* defmacro cl-defmacro defsubst define-inline
    defvar defvar-local defconst defcustom defgroup defface define-error
    defalias cl-defstruct cl-deftype cl-defgeneric cl-defmethod
    declare-function declare-functions declare-vars require provide
    eval-when-compile eval-and-compile
    ;; mode DEFINITIONS: the body runs when the mode is toggled, not at
    ;; load (the only load-time product is a defcustom/defvar + command,
    ;; i.e. more definitions), so a file of pure mode definitions is
    ;; library.  Wiring the mode in (add-hook, keybinding) is what makes
    ;; a file application, and those heads stay in the application list.
    define-minor-mode define-globalized-minor-mode define-derived-mode
    ;; comments/no-ops that carry no wiring
    put function-put)
  "Heads that define reusable code without side-effecting the editor.
Their bodies run only when called (a `defun') or merely compute a value (a
`defvar'), so the scanner does NOT descend into them.  A file built only
from these (plus `require'/`provide') is LIBRARY.")

(defconst cmacs-deps--application-heads
  '(use-package use-package! after! setq setq-default set setq-local
    add-hook remove-hook advice-add advice-remove
    with-eval-after-load eval-after-load
    define-key global-set-key local-set-key keymap-set keymap-global-set
    general-def general-define-key general-create-definer general-evil-setup
    nmap imap vmap nvmap mmap omap gmap
    defhydra pretty-hydra-define pretty-hydra-define+ major-mode-hydra-define
    transient-define-prefix add-to-list push run-with-idle-timer
    run-with-timer add-to-ordered-list
    exwm-input-set-key exwm-enable start-process)
  "Heads that wire, configure, or side-effect the running editor at load time.
Any of these reached at load time (top level, or inside a load-time wrapper)
makes a file APPLICATION.")

(defconst cmacs-deps--transparent-heads
  '(let let* progn prog1 prog2 when unless if cond and or
    dolist dotimes save-excursion save-current-buffer with-current-buffer
    ignore-errors condition-case unwind-protect catch)
  "Control/binding wrappers whose bodies run at load time.
The scanner descends through these so wiring nested inside them still counts,
while it stops at `cmacs-deps--definitional-heads' (deferred bodies).")

(defun cmacs-deps--scan-app (form acc)
  "Collect application heads reachable from FORM at LOAD time, into ACC.
Descends only load-time wrappers; stops at definitional heads (their side
effects fire when called, not at load) and at unknown calls (not decisive)."
  (if (not (consp form))
      acc
    (let ((head (car form)))
      (cond
       ((memq head cmacs-deps--application-heads) (cons head acc))
       ((memq head cmacs-deps--definitional-heads) acc)
       ((memq head cmacs-deps--transparent-heads)
        (dolist (sub (cdr form) acc)
          (setq acc (cmacs-deps--scan-app sub acc))))
       (t acc)))))

(defun cmacs-deps-classify (file)
  "Classify FILE as `library' or `application' by its load-time forms.
Return a plist: :class (`library'/`application'/`mixed'/`empty') :evidence
(alist head -> count for the application heads seen) :def-heads (defn heads
seen) :other-heads :top-forms.  A file is `application' if any wiring head is
reachable at load time (see `cmacs-deps--scan-app'), `library' if only
definitional heads appear, `mixed' if it wires but is dominated by
definitions (informational only; the tag stays `application')."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((app '()) (defs '()) (other '()) (n 0) form)
      (condition-case _err
          (while (setq form (read (current-buffer)))
            (when (consp form)
              (setq n (1+ n))
              (let ((hits (cmacs-deps--scan-app form nil))
                    (head (car form)))
                (if hits
                    (setq app (append hits app))
                  (cond ((memq head cmacs-deps--definitional-heads) (push head defs))
                        ((memq head cmacs-deps--transparent-heads) (push head other))
                        (t (push head other)))))))
        (end-of-file nil)
        (error nil))
      (let* ((evidence (let (a)
                         (dolist (h (delete-dups (copy-sequence app)) a)
                           (push (cons h (cl-count h app)) a))))
             (class (cond ((zerop n) 'empty)
                          (app (if (> (length defs) (length app)) 'mixed 'application))
                          (t 'library))))
        (list :class class
              :evidence (sort evidence (lambda (x y) (> (cdr x) (cdr y))))
              :def-heads (sort (delete-dups defs) #'string<)
              :other-heads (sort (delete-dups other) #'string<)
              :top-forms n)))))

;;;; --- environment tier (editor vs WM) -------------------------------------
;;
;; A SECOND axis, orthogonal to library/application: what runtime environment
;; a file's BEHAVIOR needs.  This is mechanical evidence only; the
;; architectural "layer" call (WM implementation vs feature touchpoint) stays
;; a human judgment.  Ruling that motivated the split: games/wc3 is tier `wm'
;; because its XF86 keybindings need EXWM (to reach them inside a fullscreen
;; game), yet it is NOT part of the WM layer - it is a feature touchpoint.
;;
;;   editor      no EXWM references; behavior testable in a plain Emacs
;;   wm-guarded  only degrade-gracefully guards (`exwm-mode' checks); testable
;;               in a plain Emacs where the guards simply never fire
;;   wm          real EXWM API references; behavior only exercisable with
;;               EXWM as the window manager (nested X / Xephyr)
;;
;; The separate :display list marks files that create frames/posframes or set
;; X-level settings: they need SOME X display (Xvfb) though not the WM.

(defconst cmacs-deps--wm-guard-symbols '(exwm-mode)
  "EXWM symbols whose reference is a degrade-gracefully check, not API use.
`exwm-mode' shows up in `derived-mode-p' guards, preview/mode exclusion
lists, and evil state lists; code referencing only it runs fine without
EXWM (the guard never fires).")

(defconst cmacs-deps--display-symbols
  '(make-frame make-frame-command set-frame-font
    x-super-keysym x-meta-keysym)
  "Symbols implying the file needs an X display (though not the WM).
Symbols prefixed `posframe-' are matched by prefix as well.")

(defun cmacs-deps--walk-symbols (form fn)
  "Call FN on every symbol occurring anywhere in FORM."
  (cond ((symbolp form) (when form (funcall fn form)))
        ((consp form)
         (cmacs-deps--walk-symbols (car form) fn)
         (cmacs-deps--walk-symbols (cdr form) fn))
        ((vectorp form)
         (mapc (lambda (x) (cmacs-deps--walk-symbols x fn)) form))))

(defconst cmacs-deps--defining-heads
  '(defun cl-defun defmacro cl-defmacro defsubst defvar defvar-local
    defconst defcustom defalias define-minor-mode define-derived-mode
    define-globalized-minor-mode)
  "Heads whose (cadr FORM) names a symbol the file itself defines.
Used to subtract a file's OWN namespace from its WM-API evidence (e.g.
browser-links deliberately lives in an `exwm-browser-link-*' namespace;
those are its definitions, not EXWM API use).")

(defun cmacs-deps--defined-names (forms)
  "Symbols defined by FORMS (top level or inside load-time wrappers)."
  (let ((names '()))
    (cl-labels ((scan (form)
                  (when (consp form)
                    (cond
                     ((and (memq (car form) cmacs-deps--defining-heads)
                           (cdr form))
                      (let ((name (cadr form)))
                        (when (and (consp name) (eq (car name) 'quote))
                          (setq name (cadr name)))
                        (when (symbolp name) (push name names))))
                     ((memq (car form) cmacs-deps--transparent-heads)
                      (mapc #'scan (cdr form)))))))
      (mapc #'scan forms))
    names))

(defun cmacs-deps-env-tier (file)
  "Classify FILE's environment tier: `wm', `wm-guarded', or `editor'.
Walks every symbol in the file's forms.  `exwm-'-prefixed symbols are WM
API use, except the guard set (`cmacs-deps--wm-guard-symbols') and names
the file itself defines (its own namespace).  A bare `exwm' (as in a
`require' or `featurep') is deliberately NOT counted: loading the library
needs no WM.  Returns a plist :tier :wm-api :wm-guards :display."
  (with-temp-buffer
    (insert-file-contents file)
    (goto-char (point-min))
    (let ((forms '()) form)
      (condition-case _err
          (while (setq form (read (current-buffer)))
            (push form forms))
        (end-of-file nil)
        (error nil))
      (setq forms (nreverse forms))
      (let ((own (cmacs-deps--defined-names forms))
            (api '()) (guards '()) (display '()))
        (dolist (f forms)
          (cmacs-deps--walk-symbols
           f
           (lambda (s)
             (let ((n (symbol-name s)))
               (cond
                ((memq s own))          ; the file's own namespace
                ((memq s cmacs-deps--wm-guard-symbols)
                 (cl-pushnew s guards))
                ((string-prefix-p "exwm-" n)
                 (cl-pushnew s api))
                ((or (memq s cmacs-deps--display-symbols)
                     (string-prefix-p "posframe-" n))
                 (cl-pushnew s display)))))))
        (list :tier (cond (api 'wm) (guards 'wm-guarded) (t 'editor))
              :wm-api (sort api #'string<)
              :wm-guards guards
              :display (sort display #'string<))))))

(defun cmacs-deps-env-tier-report ()
  "Tier every config file.  Return a list of (FEATURE TIER WM-API DISPLAY),
sorted wm first, then wm-guarded, then editor."
  (let ((rows '()))
    (dolist (f (cmacs-deps--all-files))
      (let* ((pl (cmacs-deps-env-tier f))
             (tier (plist-get pl :tier)))
        (push (list (cmacs-deps--feature-of f) tier
                    (plist-get pl :wm-api) (plist-get pl :display))
              rows)))
    (let ((order '(wm wm-guarded editor)))
      (sort (nreverse rows)
            (lambda (a b)
              (let ((ta (cl-position (nth 1 a) order))
                    (tb (cl-position (nth 1 b) order)))
                (if (/= ta tb) (< ta tb)
                  (string< (nth 0 a) (nth 0 b)))))))))

;;;; --- whole-config dependency DAG ----------------------------------------
;;
;; Three-phase, isolation-preserving, WM-safe scan:
;;   1. prepare (server, instant): dump load-path + write a prelude-prepended
;;      copy of every config file + a manifest.  No compiling here.
;;   2. compile (PLAIN SHELL, parallel): one isolated `emacs -Q --batch'
;;      byte-compile per copy, run under `xargs -P'.  Kept OFF the WM server so
;;      the 30s of work does not freeze the desktop (Emacs is the WM).
;;   3. collect (server, instant): read each copy's warnings, resolve every
;;      undefined symbol via `symbol-file' (config sibling vs package), and
;;      build the DAG + per-file classification.
;; Isolation matters: byte-compiling a file evaluates its top-level `require's
;; into the process, so compiling many files in ONE process leaks earlier
;; files' requires and hides real edges.  Separate processes reproduce exactly
;; what flycheck sees per file.

(defvar cmacs-deps-dag-dir "/tmp/cmacs-dag"
  "Working directory for the whole-config DAG scan.")

(defun cmacs-deps--all-files ()
  "Every config .el under `cmacs-deps-root', minus tooling and the loaders."
  (sort
   (seq-filter
    (lambda (f)
      (not (string-match-p "/tools/\\|/init\\.el\\'\\|/init-options\\.el\\'" f)))
    (directory-files-recursively cmacs-deps-root "\\.el\\'"))
   #'string<))

(defun cmacs-deps-dag-prepare (&optional dir)
  "Phase 1: lay out the DAG scan working area in DIR.
Writes load-path.el, one prelude-prepended NNNN.el copy per config file, and
manifest.txt (lines `NNNN<TAB>feature').  Returns the file count."
  (setq dir (or dir cmacs-deps-dag-dir))
  (when (file-directory-p dir) (delete-directory dir t))
  (make-directory dir t)
  (with-temp-file (expand-file-name "load-path.el" dir)
    (prin1 `(setq load-path ',load-path) (current-buffer)))
  (let ((files (cmacs-deps--all-files)) (i 0) (manifest '()))
    (dolist (f files)
      (let* ((id (format "%04d" i))
             (copy (expand-file-name (concat id ".el") dir)))
        (with-temp-buffer
          (insert-file-contents f)
          (goto-char (point-min)) (forward-line 1)
          (insert "(require 'prelude)\n")
          (write-region (point-min) (point-max) copy nil 'silent))
        (push (format "%s\t%s" id (cmacs-deps--feature-of f)) manifest)
        (setq i (1+ i))))
    (with-temp-file (expand-file-name "manifest.txt" dir)
      (insert (mapconcat #'identity (nreverse manifest) "\n") "\n"))
    (length files)))

(defun cmacs-deps--edges-for (out-file)
  "Resolve the undefined symbols in OUT-FILE's warnings into edge data.
Return a plist :siblings (features) :packages (libs) :unknown (names)."
  (let* ((pv (cmacs-deps--parse
              (if (file-exists-p out-file)
                  (with-temp-buffer (insert-file-contents out-file) (buffer-string))
                "")))
         (names (append (mapcar (lambda (n) (cons n 'function)) (car pv))
                        (mapcar (lambda (n) (cons n 'variable)) (cdr pv))))
         (sib '()) (pkg '()) (unk '()))
    (dolist (cell names)
      (let ((r (cmacs-deps-resolve (car cell) (cdr cell))))
        (cond ((plist-get r :sibling) (cl-pushnew (plist-get r :sibling) sib :test #'equal))
              ((plist-get r :library) (cl-pushnew (plist-get r :library) pkg :test #'equal))
              (t (push (car cell) unk)))))
    (list :siblings (sort sib #'string<)
          :packages (sort pkg #'string<)
          :unknown (sort (delete-dups unk) #'string<))))

(defun cmacs-deps-dag-collect (&optional dir)
  "Phase 3: read compiled warnings under DIR, return the DAG node list.
Each node is a plist :feature :class :siblings :packages :unknown.  Also
writes DIR/data.el (the raw node list as a readable sexp)."
  (setq dir (or dir cmacs-deps-dag-dir))
  (let ((nodes '()))
    (dolist (line (split-string
                   (with-temp-buffer
                     (insert-file-contents (expand-file-name "manifest.txt" dir))
                     (buffer-string))
                   "\n" t))
      (pcase-let ((`(,id ,feature) (split-string line "\t")))
        (let* ((out (expand-file-name (concat id ".el.out") dir))
               (real (expand-file-name (concat feature ".el") cmacs-deps-root))
               (edges (cmacs-deps--edges-for out))
               (class (plist-get (cmacs-deps-classify real) :class)))
          (push (append (list :feature feature :class class) edges) nodes))))
    (setq nodes (nreverse nodes))
    (with-temp-file (expand-file-name "data.el" dir)
      (let ((print-length nil) (print-level nil))
        (prin1 nodes (current-buffer))))
    nodes))

(provide 'cmacs-deps)
