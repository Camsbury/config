;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general (general-def) and hydra (defhydra) macros come from here, so they
;; expand in isolation instead of depending on the core/bindings hub loading
;; first.  The hydra-leader/body remap below is a runtime forward-ref,
;; suppressed by the file-local at the bottom.
(require 'core/keys-base)

(use-package command-log-mode
  :config
  (defun ck/toggle-command-logging ()
    "Toggle command logging"
    (interactive)
    (if (bound-and-true-p command-log-mode)
        (call-interactively #'global-command-log-mode)
      (progn
        (call-interactively #'command-log-mode)
        (call-interactively #'global-command-log-mode)
        (clm/toggle-command-log-buffer)))))

(use-package helm-dash
  :config
  (setq helm-dash-common-docsets
        '("C"
          "Emacs Lisp"
          "Haskell"
          "HTML"
          "JavaScript"
          "Python 3"
          "React"
          "Rust")))

(use-package helpful)

(defhydra hydra-describe (:exit t :columns 5)
  "describe"
  ("k" #'helpful-key      "key")
  ("f" #'helpful-callable "function")
  ("m" #'describe-mode    "mode")
  ("v" #'helpful-variable "variable"))

(general-def helpful-mode-map
  [remap evil-record-macro] #'kill-this-buffer)

(use-package package
  :config
  (-each '(("s-melpa" . "http://stable.melpa.org/packages/")
           ("melpa" . "http://melpa.milkbox.net/packages/"))
    (lambda (x) (add-to-list 'package-archives x t))))

(general-def Info-mode-map
  [remap Info-history] 'ignore)

(general-def 'Info-mode-map
  [remap Info-scroll-up] #'hydra-leader/body
  [remap Info-history]   #'evil-window-bottom)

(provide 'config/info)

;; Keybinding/hydra file: it forward-references the leader hydra
;; (hydra-leader/body, in the core/bindings hub) and helpful/describe commands,
;; invoked only at runtime.  Suppress just the unresolved class; keep every
;; other class live.  Removing these forward-ref edges from the DAG is what
;; dissolves the core/bindings <-> info cycle.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
