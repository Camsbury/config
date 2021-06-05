(use-package elixir-mode
  :defer t
  :config
  (general-add-hook 'elixir-mode-hook
   (list
    #'flycheck-mode
    (lambda () (add-hook 'before-save-hook 'elixir-format nil t)))))
(use-package flycheck-elixir
  :after (elixir-mode)
  :config
  (add-to-list 'flycheck-checkers 'elixir t))
(use-package flycheck-credo
  :after (elixir-mode)
  :config
  (add-to-list 'flycheck-checkers 'elixir-credo t)
  (setq flycheck-elixir-credo-strict t)
  (eval-after-load 'flycheck
    '(flycheck-credo-setup)))
(use-package flycheck-dialyxir
  :after (elixir-mode)
  (add-to-list 'flycheck-checkers 'elixir-dialyxir t)
  (eval-after-load 'flycheck
    '(flycheck-dialyxir-setup)))
(use-package flycheck-mix
  :after (elixir-mode)
  :config
  (add-to-list 'flycheck-checkers 'elixir-mix t))

(provide 'config/langs/elixir)
