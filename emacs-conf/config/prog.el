;; -*- lexical-binding: t; -*-
(use-package pkg-info)
(use-package flycheck)
(use-package flycheck-popup-tip)
;; Deferred: nothing in the config wires origami, and loading it at boot
;; drags in the deprecated `cl' package ("Package cl is deprecated" in
;; *Messages*).  The stub keeps `M-x origami-mode' working (decision 0001:
;; autoloads never activate, so deferral needs an explicit entry point).
(use-package origami
  :commands (origami-mode global-origami-mode))
(require 'config/modes/prettify-mode)

(use-package hl-todo
  :init
  (setq hl-todo-keyword-faces
        `(("TODO"  . ,(face-foreground 'warning))
          ("FIXME" . ,(face-foreground 'error))
          ("NOTE"  . ,(face-foreground 'success))
          ("CLEAN" . "#7cb8bb")
          ("USEIT" . "#dc8cc3")
          ("DEBUG" . "#ff9333")
          ("IMPL"  . "#c833ff"))))

(use-package aggressive-indent
  :config
  (add-to-list 'aggressive-indent-excluded-modes 'nix-mode)
  (add-to-list 'aggressive-indent-protected-commands 'evil-undo))

(setq tab-width 2)
(setq-default indent-tabs-mode nil)
(setq-default fill-column 80)
(setq display-fill-column-indicator-column 82)
(general-add-hook 'before-save-hook 'whitespace-cleanup)

(column-number-mode)
(show-paren-mode)
(electric-pair-mode)
(global-hl-line-mode)

;; Performant replacement for `global-auto-revert-mode'. That mode polls the
;; whole buffer list on a timer (or spins up a file-watcher per buffer), which
;; is exactly the background churn config/performance.el fights: under EXWM
;; every workspace frame reports visible, so a poll touches buffers you are not
;; even looking at. Instead we revert lazily -- only the buffers visible in the
;; current frame, and only when you switch buffer/window, refocus Emacs from
;; another app, or save. Ported from Doom's `doom-auto-revert-mode' but rebuilt
;; on stock hooks (Doom's relied on `doom-switch-*-hook'/`doom-visible-buffers').
(require 'autorevert)
(setq auto-revert-verbose t          ; tell us when a revert happens
      auto-revert-use-notify nil     ; no per-buffer file watchers
      auto-revert-stop-on-user-input nil
      revert-without-query (list ".")) ; don't prompt for unmodified buffers

(defun ck/auto-revert-buffer ()
  "Revert the current buffer if its file changed on disk.
No-op if the buffer already has its own `auto-revert-mode', the minibuffer
is active, or the file is remote (reverting remotes is expensive)."
  (unless (or auto-revert-mode
              (active-minibuffer-window)
              (and buffer-file-name
                   auto-revert-remote-files
                   (file-remote-p buffer-file-name nil t)))
    (let ((auto-revert-mode t))
      (auto-revert-handler)))
  nil)

(defun ck/auto-revert-visible-buffers (&rest _)
  "Revert stale buffers visible in the selected frame, if necessary."
  (dolist (buf (delete-dups (mapcar #'window-buffer (window-list))))
    (with-current-buffer buf
      (ck/auto-revert-buffer))))

;; Switch buffer / switch window within a frame.
(add-hook 'window-buffer-change-functions #'ck/auto-revert-visible-buffers)
(add-hook 'window-selection-change-functions #'ck/auto-revert-visible-buffers)
;; Refocus Emacs after visiting another X app (edits often happen out there).
(add-function :after after-focus-change-function #'ck/auto-revert-visible-buffers)
;; After a save, catch other visible windows onto the same file.
(add-hook 'after-save-hook #'ck/auto-revert-visible-buffers)

;; open buffers in a vertical split!
(setq split-height-threshold nil
      split-width-threshold 160)

(setq whitespace-line-column 10000
      whitespace-style '(face trailing lines-tail))

(general-add-hook 'prog-mode-hook
                  (list 'hl-todo-mode
                        'whitespace-mode
                        'display-fill-column-indicator-mode
                        'rainbow-delimiters-mode
                        'rainbow-mode
                        'display-line-numbers-mode
                        'prettify-mode
                        'aggressive-indent-mode))

(provide 'config/prog)
