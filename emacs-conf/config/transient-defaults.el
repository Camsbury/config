;; Global transient defaults  -*- lexical-binding: t; -*-
;;
;; transient is now a built-in Emacs package.  magit's command menus are built
;; on it, and more packages lean on it every release, so its defaults belong in
;; one editor-wide place rather than buried in the magit config where they used
;; to live.  Doom made the same move (out of `:tools magit' into core) once
;; transient started shipping with Emacs.

;; Keep transient's persisted state out of `user-emacs-directory', where it
;; would otherwise silently create a `transient/' dir, and put it alongside the
;; other cache state (undo-tree lives under ~/.cache/emacs too).  Set here,
;; before transient loads: these are defcustoms, and a value bound now survives
;; the later `defcustom', which will not clobber an already-bound variable.
(let ((dir (expand-file-name "transient/" "~/.cache/emacs/")))
  (setq transient-levels-file  (expand-file-name "levels.el" dir)
        transient-values-file  (expand-file-name "values.el" dir)
        transient-history-file (expand-file-name "history.el" dir)))

(with-eval-after-load 'transient
  ;; Level 7 exposes the advanced/less-common suffixes (e.g. the extra magit
  ;; push/commit switches).  Previously set in config/dev/git.el; hoisted here
  ;; so it governs every transient, not just magit's.
  (setq transient-default-level 7)
  ;; Pop the transient up directly below the window it was invoked from
  ;; (dedicated, never reusing that same window).  On a large display with many
  ;; splits this is easier to track than the default bottom-of-frame placement.
  (setq transient-display-buffer-action
        '(display-buffer-below-selected
          (dedicated . t)
          (inhibit-same-window . t)))
  ;; Keep a transient visible while typing into a minibuffer prompt it spawned
  ;; (e.g. reading an argument value) instead of hiding it.  Harmless no-op on
  ;; transient versions that predate this variable.
  (setq transient-show-during-minibuffer-read t)
  ;; Uniform escape: ESC backs out one transient level everywhere.
  (define-key transient-map [escape] #'transient-quit-one))

(provide 'config/transient-defaults)
