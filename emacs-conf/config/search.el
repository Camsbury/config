;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)
(require 'core/bindings)
(require 'core/text)


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

(use-package smex)

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
  (general-define-key
   :keymaps 'vertico-map
   "M-RET" #'vertico-exit-input
   "C-j"   #'vertico-next
   "C-M-j" #'vertico-next-group
   "C-k"   #'vertico-previous
   "C-M-k" #'vertico-previous-group
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
  ;; Hide the real minibuffer while the posframe is up.
  ;;
  ;; vertico-posframe's own hide (resize the mini window to zero height, then
  ;; vscroll its content out of view) does not work in this config: the frame
  ;; owns its minibuffer, so an active one-line mini window clamps back to a
  ;; line, and `auto-window-vscroll' is nil (init-options.el) so the vscroll
  ;; resets every redisplay.  The result is the prompt, input, and count
  ;; showing a second time at the bottom of the frame under the floating box.
  ;;
  ;; So cover the real minibuffer instead.  During a posframe session two
  ;; windows show the same minibuffer buffer: the real minibuffer window
  ;; (`window-minibuffer-p' t) and the posframe's window (a normal window on
  ;; an EXWM top-level frame, so `window-minibuffer-p' nil and no
  ;; `parent-frame').  An overlay scoped, via its `window' property, to the
  ;; real minibuffer window blanks the prompt and input there while the
  ;; posframe still shows them.  Vertico draws the count `[n/m]' with a
  ;; before-string overlay pinned at point-min, outside the cover range, so
  ;; pin it to the posframe window too.  (The candidate list needs no pin: it
  ;; is newline-led, so the one-line real minibuffer clips it below the fold
  ;; and it never leaks.)  Finally the real
  ;; minibuffer window is selected (cursor from `cursor-type') while the
  ;; posframe window is not (cursor from `cursor-in-non-selected-windows'):
  ;; kill the former, keep a box for the latter.  Everything is undone on
  ;; minibuffer exit so a later plain minibuffer is untouched.
  (defvar-local ck/vertico-posframe--cover-ov nil
    "Overlay blanking the real minibuffer window during a posframe session.")
  (defun ck/vertico-posframe--cover (&rest _)
    "Blank the real minibuffer window while vertico-posframe shows its
buffer in a child frame.  See the comment above `vertico-posframe-mode'
for why vertico-posframe's built-in hide fails in this config."
    (ignore-errors
      (let* ((mbwin (active-minibuffer-window))
             (b1 (and (window-live-p mbwin) (window-buffer mbwin)))
             (pfwin (and (bufferp b1)
                         (seq-find (lambda (w)
                                     (and (not (eq w mbwin))
                                          (not (window-minibuffer-p w))))
                                   (get-buffer-window-list b1 nil t)))))
        (when (and (window-live-p mbwin) (bufferp b1)
                   (not (vertico-posframe--show-minibuffer-p)))
          (with-current-buffer b1
            ;; REAR-ADVANCE t: a character typed at the end of the input is
            ;; absorbed into the overlay as it is inserted, so it never
            ;; flashes in the real minibuffer before the next re-cover.
            (unless (overlayp ck/vertico-posframe--cover-ov)
              (setq ck/vertico-posframe--cover-ov
                    (make-overlay (point-min) (point-max) nil nil t)))
            (move-overlay ck/vertico-posframe--cover-ov (point-min) (point-max))
            (overlay-put ck/vertico-posframe--cover-ov 'window mbwin)
            (overlay-put ck/vertico-posframe--cover-ov 'display "")
            (setq-local cursor-type nil
                        cursor-in-non-selected-windows 'box)
            (when (and (window-live-p pfwin)
                       (boundp 'vertico--count-ov) (overlayp vertico--count-ov))
              (overlay-put vertico--count-ov 'window pfwin)))))))
  (defun ck/vertico-posframe--uncover ()
    "Undo `ck/vertico-posframe--cover' when the minibuffer exits."
    (when (overlayp ck/vertico-posframe--cover-ov)
      (delete-overlay ck/vertico-posframe--cover-ov)
      (setq ck/vertico-posframe--cover-ov nil))
    (kill-local-variable 'cursor-type)
    (kill-local-variable 'cursor-in-non-selected-windows)
    ;; Drop the frozen cursor anchor so the next minibuffer re-anchors.
    (ck/posframe-point-anchor-reset))
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

(with-eval-after-load 'grep
  (evil-set-initial-state 'grep-mode 'normal)
  (general-evil-define-key 'normal 'grep-mode-map
    "q" #'quit-window))

(provide 'config/search)
