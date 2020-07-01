(use-package bindings-conf)
(use-package rust-mode)
(use-package flycheck-rust)

(general-def 'normal rust-mode-map
 [remap empty-mode-leader] #'hydra-rust/body)

(with-eval-after-load 'rust-mode
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

(setq racer-cmd "racer")

(general-add-hook
 'rust-mode-hook
 (list
  #'cargo-minor-mode
  #'racer-mode
  ;; #'flycheck-mode
  (lambda () (add-hook 'before-save-hook #'rust-format-buffer))))
;; `(
;; ,(lambda () (call-interactively #'cargo-minor-mode))
;; ,(lambda () (call-interactively #'racer-mode))
;; ,(lambda () (call-interactively #'flycheck-mode))
;; ,(lambda () (add-hook 'before-save-hook #'rust-format-buffer)))




(defhydra hydra-rust (:exit t)
  "rust-mode"
  ("l" #'rust-run "run buffer"))

(provide 'langs/rust-conf)
