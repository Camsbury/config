;; scratch buffer options
(setq initial-scratch-message
      "#+TITLE: Scratch Buffer

* scratch")

(with-current-buffer "*scratch*"
  (call-interactively #'org-mode))

(provide 'config/scratch)
