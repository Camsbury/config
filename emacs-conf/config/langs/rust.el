(use-package rust-mode)
(use-package flycheck-rust :after (rust-mode))
(use-package cargo)
(use-package racer
  :config
  (setq racer-cmd "racer"))

(general-def 'normal rust-mode-map
 [remap empty-mode-leader] #'hydra-rust/body)

(with-eval-after-load 'rust-mode
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

(general-add-hook
 'rust-mode-hook
 (list
  #'cargo-minor-mode
  #'racer-mode
  ;; #'flycheck-mode
  ;; this is running for EVERYTHING - make it only for rust-mode
  ;; (lambda () (add-hook 'before-save-hook #'rust-format-buffer))
  ))
;; `(
;; ,(lambda () (call-interactively #'cargo-minor-mode))
;; ,(lambda () (call-interactively #'racer-mode))
;; ,(lambda () (call-interactively #'flycheck-mode))
;; ,(lambda () (add-hook 'before-save-hook #'rust-format-buffer)))


(defhydra hydra-rust (:exit t)
  "rust-mode"
  ("l" #'rust-run "run buffer"))

(provide 'config/langs/rust)
