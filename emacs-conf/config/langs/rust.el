(use-package rust-mode
  :custom
  (lsp-rust-analyzer-cargo-watch-command "clippy")
  (lsp-rust-analyzer-server-display-inlay-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints nil)
  (lsp-rust-analyzer-display-reborrow-hints nil))
(use-package flycheck-rust
  :after (rust-mode))
(use-package rustic
  :after (rust-mode)
  :custom
  (rustic-format-on-save t)
  (rustic-default-clippy-arguments "--benches --tests --all-features -- -W clippy::pedantic")
  :config
  (setq rustic-clippy-arguments "--benches --tests --all-features -- -W clippy::pedantic")
  (add-to-list 'flycheck-checkers 'rustic-clippy t))
(use-package cargo
  :config
  (setq exec-path (append exec-path '("~/.cargo/bin"))))

(general-def 'normal rust-mode-map
 [remap empty-mode-leader] #'hydra-rust/body)

(with-eval-after-load 'rust-mode
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup))

(general-add-hook
 'rust-mode-hook
 (lambda ()
   (setq rustic-cargo-bin (getenv "CARGO_PATH"))
   (setq rustic-rustfmt-bin (getenv "RUSTFMT_PATH"))
   (lsp-dependency
    'rust-analyzer
    `(:system ,(getenv "RUST_ANALYZER"))
    '(:system "rust-analyzer"))
   ;; (cargo-minor-mode)
   (lsp-deferred)
   (flycheck-add-next-checker
    'lsp
    '(info . rustic-clippy))
   (flycheck-mode)))

;; (dap-register-debug-template
;;  "Rust::GDB Run Configuration"
;;  (list :type "gdb"
;;        :request "launch"
;;        :name "GDB::Run"
;;        :gdbpath "rust-gdb"
;;        :target nil
;;        :cwd nil))

(defun rustic-cargo-run-with-args ()
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively #'rustic-cargo-run)))


(defhydra hydra-rust (:exit t)
  "rust-mode"
  ("c" #'rust-compile                "compile")
  ("C" #'rust-compile-release        "compile-release")
  ("d" #'lsp-describe-thing-at-point "describe thing")
  ("g" #'rust-dbg-wrap-or-unwrap     "wrap debug")
  ("r" #'rustic-cargo-run            "run project")
  ("R" #'rustic-cargo-run-with-args  "run project with args")
  ("m" #'rust-toggle-mutability      "toggle mutability")
  ("t" #'rustic-cargo-test           "run tests"))

(provide 'config/langs/rust)
