;; -*- lexical-binding: t; -*-
;; TODO: autoloads need looking into: package activation is restricted, and
;; bare `:defer t' creates no entry stubs, so this never loads (.ex/.exs get
;; fundamental-mode) and flycheck-elixir's `:after' never fires.
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

;; use-package config: forward-refs general-add-hook and deferred flycheck
;; commands invoked only at runtime.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
