(when (string-equal system-type "gnu/linux")
    (progn
      (require 'flycheck-credo)
      (require 'flycheck-dialyxir)
      (require 'flycheck-elixir)
      (require 'flycheck-mix)

      ;;; flycheck setup
      (add-to-list 'flycheck-checkers 'elixir t)
      (add-to-list 'flycheck-checkers 'elixir-credo t)
      (add-to-list 'flycheck-checkers 'elixir-dialyxir t)
      (add-to-list 'flycheck-checkers 'elixir-mix t)

      (setq flycheck-elixir-credo-strict t)
      (eval-after-load 'flycheck
        '(flycheck-credo-setup))
      (eval-after-load 'flycheck
        '(flycheck-dialyxir-setup))

      ;;; mode hooks
      (general-add-hook 'elixir-mode-hook
                        (list
                         #'flycheck-mode
                         (lambda () (add-hook 'before-save-hook 'elixir-format nil t))))))

(provide 'elixir-conf)
