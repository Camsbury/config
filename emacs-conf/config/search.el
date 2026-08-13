;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'core/bindings)
(require 'core/text)

;; `crm-separator' is owned by crm.el (completing-read-multiple), referenced in
;; `ck/crm-indicator' before that library loads.
(declare-vars crm-separator)


(use-package projectile
  :config (projectile-mode)

  (customize-set-variable
   'projectile-project-search-path '(("~/projects" . 2)))

  (customize-set-variable
   'projectile-ignored-project-function
   (lambda (project)
     (string-match
      (rx
       (or
        (seq bos "/nix")
        (seq "/."
             (one-or-more (not (any "/.")))
             eos)
        ".git"
        "dist"
        "dist-newstyle"))
      project)))

  (customize-set-variable
   'projectile-keymap-prefix (kbd "C-c C-p"))

  (customize-set-variable
   'projectile-current-project-on-switch 'keep))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Others

(use-package wgrep
  :config
  (setq wgrep-change-readonly-file t)
  ;; NOTE: C-c C-p is the thing if you are looking for writable grep
  (defun ck/wgrep-save-and-quit ()
    "wgrep save everything and quit the window"
    (interactive)
    (wgrep-finish-edit)
    (wgrep-save-all-buffers)
    (quit-window))
  (general-define-key
   :keymaps 'wgrep-mode-map
   [remap evil-save-modified-and-close] #'ck/wgrep-save-and-quit))

(use-package dumb-jump
  :init
  (setq dumb-jump-prefer-searcher 'rg))

(general-emacs-define-key xref--button-map
  "q"   #'kill-buffer-and-window
  "RET" #'xref-goto-xref)

(customize-set-variable
 'recentf-max-saved-items 100)
(customize-set-variable
 'recentf-exclude
 (list
  (rx
   (or ".metals"
       ".m2"
       ".emacs.d/emms"
       ".elfeed"
       (seq bos "/nix")))))
(recentf-mode)
(savehist-mode 1)
(setq history-length 500
      history-delete-duplicates nil)
(minibuffer-electric-default-mode)

;; Hide commands that do not apply to the current buffer's major/minor modes
;; from `M-x' completion (e.g. no org-only commands while in a prog buffer).
;; The built-in predicate honors each command's declared applicability
;; (`:completion-predicate' / `interactive' MODES), so genuinely global
;; commands still show everywhere.
(setq read-extended-command-predicate #'command-completion-default-include-p)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Emacs Nouveau

;; core UI
(use-package vertico
  :config
  (vertico-mode 1)
  (require 'vertico-sort)
  (setq
   vertico-resize nil
   vertico-count 17
   vertico-cycle t
   vertico-sort-function #'vertico-sort-history-length-alpha)
  (setq-default
   completion-in-region-function
   (lambda (&rest args)
     (apply (if vertico-mode
                #'consult-completion-in-region
              #'completion--in-region)
            args)))
  ;; Replace the WHOLE minibuffer path with the clipboard in one key.  Plain
  ;; `yank' appends to the current directory, and `vertico-directory-tidy'
  ;; only collapses the shadowed prefix on `self-insert-command' (typing a
  ;; `/'), never on a yank -- so a paste leaves `~/dir//pasted/path'.  Deleting
  ;; the field first means there is no prefix to double up, so no tidy needed.
  (defun ck/minibuffer-replace-with-clipboard ()
    "Replace the whole minibuffer contents with the clipboard, then yank.
In `find-file' this swaps the entire path for the clipboard in one step."
    (interactive)
    (delete-minibuffer-contents)
    (yank))
  (general-define-key
   :keymaps 'vertico-map
   "M-RET" #'vertico-exit-input
   "C-j"   #'vertico-next
   "C-M-j" #'vertico-next-group
   "C-k"   #'vertico-previous
   "C-M-k" #'vertico-previous-group
   "C-S-y" #'ck/minibuffer-replace-with-clipboard
   [escape] #'minibuffer-keyboard-quit))

;; NOTE: still want this to only work for find-file
;; Configure directory extension.
(use-package vertico-directory
  :after vertico
  :ensure nil
  ;; More convenient directory navigation commands
  :bind (:map vertico-map
              ("M-DEL" . #'vertico-directory-up)
              ("RET" . vertico-directory-enter))
  ;; Tidy shadowed file names
  :hook (rfn-eshadow-update-overlay . vertico-directory-tidy))

;; Resume the last minibuffer session (query, candidate, position).  The
;; save hook must run for every minibuffer so there is a session to repeat.
;; `:after' alone would never `require' the extension, so `:demand'.
(use-package vertico-repeat
  :ensure nil
  :demand t
  :after vertico
  :init
  (add-hook 'minibuffer-setup-hook #'vertico-repeat-save)
  :config
  (general-define-key :keymaps 'global-map
   "C-c '" #'vertico-repeat))

;; Per-category / per-command display config, plus candidate highlighting:
;; directories get the dir face, and in `M-x' any command that names a
;; currently-enabled major/minor mode is highlighted.  Pure text-property
;; transforms (no frames), so EXWM-safe.
(use-package vertico-multiform
  :ensure nil
  :demand t
  :after vertico
  :config
  (vertico-multiform-mode 1)
  (defvar ck/vertico-transform-functions nil
    "Functions applied to each vertico candidate string before display.")
  ;; Only wrap formatting when a transform is actually set for this
  ;; category/command (the &context specializer fires when the var is
  ;; non-nil).  `add-face-text-property' + `append' preserves match faces.
  (cl-defmethod vertico--format-candidate :around
    (cand prefix suffix index start
          &context ((not ck/vertico-transform-functions) null))
    (dolist (fun (ensure-list ck/vertico-transform-functions))
      (setq cand (funcall fun cand)))
    (cl-call-next-method cand prefix suffix index start))
  (defun ck/vertico-highlight-directory (file)
    "Face FILE as a directory when it ends in a slash."
    (when (string-suffix-p "/" file)
      (add-face-text-property 0 (length file)
                              'marginalia-file-priv-dir 'append file))
    file)
  (defun ck/vertico-highlight-enabled-mode (cmd)
    "Face CMD when it names a currently-enabled major/minor mode."
    (let ((sym (intern cmd)))
      (with-current-buffer (nth 1 (buffer-list))
        (when (or (eq sym major-mode)
                  (and (memq sym minor-mode-list)
                       (boundp sym)
                       (symbol-value sym)))
          (add-face-text-property 0 (length cmd)
                                  'font-lock-constant-face 'append cmd)))
      cmd))
  (add-to-list 'vertico-multiform-categories
               '(file (ck/vertico-transform-functions
                       . ck/vertico-highlight-directory)))
  (add-to-list 'vertico-multiform-commands
               '(execute-extended-command
                 (ck/vertico-transform-functions
                  . ck/vertico-highlight-enabled-mode))))

;; Render the vertico minibuffer in a centered floating child frame.
;; From GNU ELPA (declared in nix-conf/packages/emacs.nix, elpaPackages);
;; the `:if (locate-library ...)' guard keeps this inert until the rebuild
;; lands, so a restart before the rebuild does not error on a missing pkg.
;;
;; Enabled as a plain global mode on purpose: posframe is NOT one of the
;; display modes vertico-multiform manages (buffer/flat/grid/reverse/
;; unobtrusive/vertical), so the global mode is orthogonal to our multiform
;; candidate-transform highlighting and the two compose cleanly.  Do NOT add
;; `posframe' to vertico-multiform settings as well, that would double-manage
;; the mode (per the vertico-posframe README).  Childframes are EXWM-safe
;; here (corfu already draws them).
;; The cover itself (blanking the real minibuffer under the box) lives in
;; config/prompts.el, which floats every OTHER kind of prompt through the same
;; machinery; only the vertico-specific parts stay here.
(declare-functions "config/prompts"
  ck/prompt-posframe-cover ck/prompt-posframe-uncover)

(use-package vertico-posframe
  :if (locate-library "vertico-posframe")
  :demand t
  :after vertico
  :config
  ;; Anchor the floating minibuffer at the cursor (not dead centre), clamped on
  ;; screen and frozen for the session so previewing commands do not bounce it.
  ;; The poshandler is the shared `ck/posframe-poshandler-point' from
  ;; core/bindings.el (also used by hydra hints); the anchor is cleared in
  ;; `ck/vertico-posframe--uncover' on minibuffer exit.
  ;;
  ;; Default min-width is 62% of the frame, which leaves a wide band of empty
  ;; space to the right of short candidates (and pushes marginalia annotations
  ;; out to that far edge).  A small floor lets the box hug its content, while
  ;; the cap keeps long file paths from sprawling across the whole frame.
  (setq vertico-posframe-poshandler #'ck/posframe-poshandler-point
        vertico-posframe-border-width 3
        vertico-posframe-min-width 40
        vertico-posframe-width 100
        vertico-posframe-parameters '((left-fringe . 8)
                                      (right-fringe . 8)))
  ;; Hide the real minibuffer while the posframe is up, through the shared
  ;; cover in config/prompts.el (see that file for why vertico-posframe's own
  ;; hide cannot work in this config).  What is vertico's alone stays here:
  ;; the package's rule for deliberately showing the real minibuffer, and the
  ;; candidate count `[n/m]', which vertico draws as a before-string overlay
  ;; pinned at point-min, outside the cover range, so it has to be re-scoped to
  ;; the posframe's window by hand.  (The candidate list needs no pin: it is
  ;; newline-led, so the one-line real minibuffer clips it below the fold and
  ;; it never leaks.)
  (defun ck/vertico-posframe--cover (&rest _)
    "Blank the real minibuffer window while vertico-posframe shows its buffer."
    (ignore-errors
      (unless (vertico-posframe--show-minibuffer-p)
        (let ((pfwin (ck/prompt-posframe-cover)))
          (when (and (window-live-p pfwin)
                     (boundp 'vertico--count-ov) (overlayp vertico--count-ov))
            (overlay-put vertico--count-ov 'window pfwin))))))
  (defun ck/vertico-posframe--uncover ()
    "Undo `ck/vertico-posframe--cover' when the minibuffer exits."
    (ck/prompt-posframe-uncover))
  (advice-add 'vertico-posframe--show :after #'ck/vertico-posframe--cover)
  (add-hook 'minibuffer-exit-hook #'ck/vertico-posframe--uncover)
  (vertico-posframe-mode 1))

(use-package orderless
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles . (partial-completion)))))
  ;; Space-separated components; escape space with \  when needed.
  (orderless-component-separator #'orderless-escapable-split-on-space)
  :config
  ;; Per-component matching styles via an affix character on a component:
  ;;   !foo  without-literal   =foo  literal        ^foo  literal-prefix
  ;;   `foo  initialism        ~foo  flex           %foo  char-fold
  ;;   &foo  annotation
  ;; The affix may be a prefix or a suffix and can be escaped with a
  ;; backslash.  A bare "foo$" anchors at end; a bare ".ext" matches a file
  ;; extension.  Adapted from doom's dispatchers.
  (setq orderless-affix-dispatch-alist
        '((?! . orderless-without-literal)
          (?& . orderless-annotation)
          (?% . char-fold-to-regexp)
          (?` . orderless-initialism)
          (?= . orderless-literal)
          (?^ . orderless-literal-prefix)
          (?~ . orderless-flex))
        orderless-style-dispatchers
        '(ck/orderless-dispatch
          ck/orderless-disambiguation-dispatch))

  (defun ck/orderless-dispatch (pattern _index _total)
    "Like `orderless-affix-dispatch' but affixes may be escaped."
    (let ((len (length pattern))
          (alist orderless-affix-dispatch-alist))
      (when (> len 0)
        (cond
         ((and (= len 1) (alist-get (aref pattern 0) alist)) #'ignore)
         ((when-let* ((style (alist-get (aref pattern 0) alist))
                      ((not (char-equal (aref pattern (max (1- len) 1)) ?\\))))
            (cons style (substring pattern 1))))
         ((when-let* ((style (alist-get (aref pattern (1- len)) alist))
                      ((not (char-equal (aref pattern (max 0 (- len 2))) ?\\))))
            (cons style (substring pattern 0 -1))))))))

  (defun ck/orderless-disambiguation-dispatch (word _index _total)
    "Anchor WORD ending in $, and match .ext against file extensions."
    (let ((tofu-re (if (boundp 'consult--tofu-regexp)
                       (concat consult--tofu-regexp "*\\'")
                     "\\'")))
      (cond
       ((string-suffix-p "$" word)
        `(orderless-regexp . ,(concat (substring word 0 -1) tofu-re)))
       ((and (or minibuffer-completing-file-name
                 (derived-mode-p 'eshell-mode))
             (string-match-p "\\`\\.." word))
        `(orderless-regexp . ,(concat "\\." (substring word 1) tofu-re)))))))
;; Enable rich annotations using the Marginalia package
(use-package marginalia
  ;; Bind `marginalia-cycle' locally in the minibuffer.  To make the binding
  ;; available in the *Completions* buffer, add it to the
  ;; `completion-list-mode-map'.
  :demand t
  :bind (:map minibuffer-local-map
              ("M-a" . marginalia-cycle))

  :config
  (marginalia-mode 1)
  ;; Give these commands the right annotator category so their candidates
  ;; get buffer/mode annotations instead of the plain default.
  (dolist (cat '((projectile-switch-to-buffer . buffer)
                 (flycheck-error-list-set-filter . builtin)))
    (add-to-list 'marginalia-command-categories cat))
  (general-define-key :keymaps 'minibuffer-local-map
   "M-a" #'marginalia-cycle))
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))
;; power commands / actions
(use-package consult
  :preface
  (general-define-key
   :keymaps 'global-map
   [remap bookmark-jump]                 #'consult-bookmark
   [remap evil-show-marks]               #'consult-mark
   [remap evil-show-registers]           #'consult-register
   [remap goto-line]                     #'consult-goto-line
   [remap imenu]                         #'consult-imenu
   [remap Info-search]                   #'consult-info
   [remap locate]                        #'consult-locate
   [remap load-theme]                    #'consult-theme
   [remap recentf-open-files]            #'consult-recent-file
   [remap switch-to-buffer]              #'consult-buffer
   [remap switch-to-buffer-other-window] #'consult-buffer-other-window
   [remap switch-to-buffer-other-frame]  #'consult-buffer-other-frame
   [remap yank-pop]                      #'consult-yank-pop)
  :config
  (setq consult-ripgrep-args
        (concat
         "rg --null --line-buffered --color=never --max-columns=1000 \
          --path-separator / --smart-case --no-heading --line-number \
          --hidden --ignore-file "
         user-home-path
         "/.rgignore")
        consult-narrow-key "<"
        consult-line-numbers-widen t
        consult-async-min-input 2
        consult-async-refresh-delay  0.15
        consult-async-input-throttle 0.2
        consult-async-input-debounce 0.1)

  ;; Never auto-preview EXWM buffers.  An EXWM buffer *is* an X client window,
  ;; so consult's preview `switch-to-buffer' physically yanks that window into
  ;; the current frame/workspace, wrecking the layout.  Skip preview for them
  ;; (selection on RET still switches normally); regular buffers preview as
  ;; before.
  (setq consult-preview-excluded-buffers '(derived-mode . exwm-mode))

  ;; Gate the heavy previews behind `C-SPC' instead of auto-previewing every
  ;; candidate: ripgrep/grep hits, recent files and bookmarks preview only on
  ;; demand, and `consult-theme' only after a debounce (so scrolling the
  ;; theme list does not reload a theme per candidate).
  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file
   consult-source-recent-file consult-source-project-recent-file
   consult-source-bookmark
   :preview-key "C-SPC")
  (consult-customize
   consult-theme
   :preview-key '("C-SPC" :debounce 0.5 any)))
(use-package consult-imenu)
(use-package consult-projectile)
;; Show a `[CRM<sep>]' prefix on completing-read-multiple prompts so it is
;; obvious you can select several candidates (separator, e.g. a comma).
(defun ck/crm-indicator (args)
  (cons (format "[CRM%s] %s"
                (replace-regexp-in-string
                 "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" "" crm-separator)
                (car args))
        (cdr args)))
(advice-add #'completing-read-multiple :filter-args #'ck/crm-indicator)

(use-package embark
  ;; NOTE: you want to C-c C-p after this to edit all
  :bind (("C-c C-o" . embark-export)
         ("C-." . embark-act))
  :config
  (defun ck/embark-export-write ()
    "Export the current candidates to a writable buffer.
consult-grep -> wgrep, file -> wdired, consult-location -> occur-edit,
consult-xref -> xref-edit (Emacs 31+).  Edit, then save as usual."
    (interactive)
    (require 'embark)
    (require 'wgrep)
    (let* ((edit-command
            (pcase-let ((`(,type . ,_)
                         (run-hook-with-args-until-success
                          'embark-candidate-collectors)))
              (pcase type
                ('consult-grep #'wgrep-change-to-wgrep-mode)
                ('file #'wdired-change-to-wdired-mode)
                ('consult-location #'occur-edit-mode)
                ('consult-xref
                 (if (fboundp 'xref-change-to-xref-edit-mode)
                     #'xref-change-to-xref-edit-mode
                   (user-error "Writable xref export requires Emacs 31+")))
                (x (user-error
                    "Embark category %S has no writable export" x)))))
           (embark-after-export-hook
            `(,@embark-after-export-hook ,edit-command)))
      (embark-export)))
  (general-define-key :keymaps 'minibuffer-local-map
   "C-c C-e" #'ck/embark-export-write))
(use-package embark-consult
  ;; `:after' + `:hook' alone never emit a `require', so this glue package
  ;; would never load; `:demand' fires the load once embark and consult are in.
  :demand t
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Edit the current search in a real buffer, mirroring isearch's `M-e'
;; (`isearch-edit-string').  M-e captures the session (invoking command,
;; base args, directory, input), CLOSES the minibuffer, then opens the
;; edit buffer.  `C-c C-c' relaunches the command with the edited values;
;; `C-c C-k' relaunches it with the originals.  No minibuffer stays alive
;; behind the edit, so recursive minibuffers stay disabled and no
;; abandoned session lingers to block later minibuffer commands.
;;
;; For consult grep-style sessions the edit buffer shows the FULL
;; expression in two sections: the base command args (e.g.
;; `consult-ripgrep-args') and the minibuffer input.  Edited args are in
;; effect for the relaunched search only, since consult captures the args
;; in a closure at session start.  Within each section lines join with
;; spaces, so flags can sit one per line while editing.  Any other
;; minibuffer gets the input-only version of the same flow, relaunched
;; via `call-interactively'.
(defvar ck/minibuffer-edit--grep-args-vars
  '((consult-ripgrep  . consult-ripgrep-args)
    (consult-grep     . consult-grep-args)
    (consult-git-grep . consult-git-grep-args))
  "Consult grep-style commands mapped to their base-args variable.")

(defun ck/minibuffer-edit--underlying-command (command)
  "Resolve COMMAND to the command it wraps, unwrapping hydra heads.
A hydra head runs as a generated wrapper such as
`hydra-leader/consult-ripgrep-and-exit', and that wrapper is what
`current-minibuffer-command' reports, so the args-var lookup (and any
relaunch) must use the wrapped command instead.
COMMAND may be any binding target, not just a symbol: upstream packages
bind keys and buttons to closures (eca-chat's resume entry runs as
`(lambda (&rest _) (eca-chat-resume))'), and `this-command' carries that
closure verbatim.  Only symbols can be hydra wrappers, so anything else
passes through unchanged."
  (let ((name (and (symbolp command) command (symbol-name command))))
    (if (and name
             (string-match "\\`hydra-[^/]+/\\(.+?\\)\\(-and-exit\\)?\\'" name))
        (intern (match-string 1 name))
      command)))

(defvar ck/minibuffer-edit--invoking-command nil
  "Command that opened the innermost minibuffer, captured at setup time.
`current-minibuffer-command' only means \"the invoker\" inside
minibuffer hooks; by the time a later command in the session reads it,
it mirrors `this-command' again, so we capture the invoker ourselves.")

(defun ck/minibuffer-edit--capture-invoker ()
  "Record which command is opening this minibuffer."
  (setq ck/minibuffer-edit--invoking-command
        (ck/minibuffer-edit--underlying-command this-command)))

(add-hook 'minibuffer-setup-hook #'ck/minibuffer-edit--capture-invoker)

(defvar-local ck/minibuffer-edit--session nil
  "Plist for the captured minibuffer session this edit buffer edits.
Keys: :command, :args-var, :args, :dir, :input.")

(defconst ck/minibuffer-edit--args-header
  ";; Base command args -- editing these relaunches the search:")

(defun ck/minibuffer-edit--args-lines (args)
  "Render ARGS with each flag starting its own line, for easy editing.
A flag's value stays on the flag's line; the section parser joins the
lines back with spaces on confirm."
  (replace-regexp-in-string "[ \t]+\\(--\\)" "\n\\1" args))

(defconst ck/minibuffer-edit--input-header
  ";; Minibuffer input:")

(defvar-keymap ck/minibuffer-input-edit-mode-map
  "C-c C-c" #'ck/minibuffer-input-edit-confirm
  "C-c C-k" #'ck/minibuffer-input-edit-abort)

(define-derived-mode ck/minibuffer-input-edit-mode text-mode "MiniEdit"
  "Edit a minibuffer input string in a full buffer."
  (setq-local header-line-format
              "Edit search -- C-c C-c: apply, C-c C-k: restore original (lines join with spaces)"))

(defun ck/minibuffer-edit-input ()
  "Capture the minibuffer session, close it, and edit it in a buffer.
Everything a relaunch needs (command, args, directory, input) is read
here; the session itself is aborted before the edit buffer opens, so no
live minibuffer waits behind the edit."
  (interactive)
  (unless (minibufferp)
    (user-error "No active minibuffer input to edit"))
  (let* ((command ck/minibuffer-edit--invoking-command)
         (args-var (alist-get command ck/minibuffer-edit--grep-args-vars))
         (session (list :command command
                        :args-var args-var
                        :args (and args-var (symbol-value args-var))
                        :dir default-directory
                        :input (minibuffer-contents))))
    (unless (commandp command)
      (user-error "Cannot relaunch this minibuffer's command (%S)" command))
    ;; `abort-minibuffers' throws out of this command, so nothing after
    ;; it runs: hand the buffer setup to a poller first.
    (ck/minibuffer-edit--open-when-clear session (minibuffer-depth))
    (abort-minibuffers)))

(defun ck/minibuffer-edit--open-when-clear (session depth &optional tries)
  "Open SESSION's edit buffer once minibuffer DEPTH has unwound.
A zero-delay timer can fire during the aborted session's teardown
(consult kills its rg process inside the minibuffer's unwind, and that
process wait runs timers), so poll until the depth drops below DEPTH,
the aborted session's depth.  Give up after ~2s."
  (let ((tries (or tries 0)))
    (cond
     ((< (minibuffer-depth) depth)
      (ck/minibuffer-edit--open session))
     ((> tries 40)
      (message "Minibuffer edit abandoned: the aborted session never exited"))
     (t
      (run-with-timer 0.05 nil #'ck/minibuffer-edit--open-when-clear
                      session depth (1+ tries))))))

(defun ck/minibuffer-edit--open (session)
  "Pop up the edit buffer for the captured SESSION."
  (let ((buf (get-buffer-create "*minibuffer input edit*")))
    (with-current-buffer buf
      (erase-buffer)
      (ck/minibuffer-input-edit-mode)
      (setq ck/minibuffer-edit--session session)
      (when (plist-get session :args-var)
        (insert ck/minibuffer-edit--args-header "\n"
                (ck/minibuffer-edit--args-lines (plist-get session :args))
                "\n\n"
                ck/minibuffer-edit--input-header "\n"))
      (insert (plist-get session :input))
      (goto-char (point-max)))
    ;; `pop-to-buffer' rather than `select-window' + `display-buffer':
    ;; the latter returns nil when no window takes the buffer, and
    ;; `select-window' on nil dies with an opaque wrong-type-argument.
    (pop-to-buffer buf)))

(defun ck/minibuffer-edit--section (header)
  "Return the space-joined lines of the section under HEADER, else nil."
  (save-excursion
    (goto-char (point-min))
    (when (search-forward header nil t)
      (let ((beg (min (point-max) (1+ (line-end-position))))
            (end (if (re-search-forward "^;;" nil t)
                     (line-beginning-position)
                   (point-max))))
        (string-join
         (delete "" (mapcar #'string-trim
                            (split-string (buffer-substring beg end) "\n")))
         " ")))))

(defun ck/minibuffer-edit--relaunch (command args-var args dir input)
  "Run COMMAND with INPUT preinserted in its minibuffer.
Grep-style commands (ARGS-VAR non-nil) run in DIR with ARGS-VAR set to
ARGS for just that session; anything else relaunches via
`call-interactively'."
  (minibuffer-with-setup-hook
      (lambda ()
        (delete-minibuffer-contents)
        (insert input))
    (if args-var
        (let ((old (symbol-value args-var)))
          (set args-var args)
          (unwind-protect
              (funcall command dir)
            (set args-var old)))
      (call-interactively command))))

(defun ck/minibuffer-edit--relaunch-session (session args input)
  "Relaunch SESSION's command with ARGS and INPUT, closing the edit buffer."
  (quit-window t)
  (ck/minibuffer-edit--relaunch (plist-get session :command)
                                (plist-get session :args-var)
                                args
                                (plist-get session :dir)
                                input))

(defun ck/minibuffer-input-edit-confirm ()
  "Relaunch the captured command with the edited args and input."
  (interactive)
  (let* ((session ck/minibuffer-edit--session)
         (args-var (plist-get session :args-var))
         (new-args (and args-var
                        (or (ck/minibuffer-edit--section
                             ck/minibuffer-edit--args-header)
                            (user-error "Base-args section header missing"))))
         (input (if args-var
                    (or (ck/minibuffer-edit--section
                         ck/minibuffer-edit--input-header)
                        (user-error "Input section header missing"))
                  (string-join
                   (delete "" (mapcar #'string-trim
                                      (split-string (buffer-string) "\n")))
                   " "))))
    (ck/minibuffer-edit--relaunch-session session new-args input)))

(defun ck/minibuffer-input-edit-abort ()
  "Abandon the edit and relaunch with the original args and input."
  (interactive)
  (let ((session ck/minibuffer-edit--session))
    (ck/minibuffer-edit--relaunch-session session
                                          (plist-get session :args)
                                          (plist-get session :input))))

(general-define-key :keymaps 'minibuffer-local-map
 "M-e" #'ck/minibuffer-edit-input)

(with-eval-after-load 'grep
  (evil-set-initial-state 'grep-mode 'normal)
  (general-evil-define-key 'normal 'grep-mode-map
    "q" #'quit-window))

(provide 'config/search)

;; use-package config file: the undefined functions are the packages' own APIs
;; (vertico/consult/embark/wgrep/... deferred, so never loaded at compile time)
;; and the few `ck/*' commands defined inside `:config' blocks and forward-
;; referenced from bindings.  Suppress just the unresolved class; every other
;; class stays live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
