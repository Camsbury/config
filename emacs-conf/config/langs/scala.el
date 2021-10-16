(require 'prelude)

(use-package ammonite-term-repl)
(use-package scala-mode)
(general-add-hook
 'scala-mode-hook
 (lambda ()
   (progn
     (lsp-register-custom-settings
      `(("metals.java-home" ,(getenv "JAVA_HOME"))))
     (lsp-dependency
      'metals
      `(:system ,(concat (getenv "METALS_PATH") "/metals-emacs"))
      '(:system "metals"))
     (lsp-deferred)
     (flycheck-add-next-checker 'lsp 'scala))))



(use-package lsp-metals)
(customize-set-variable 'lsp-metals-server-args
                        '("-J-Dmetals.allow-multiline-string-formatting=off"))


(use-package sbt-mode
  :config
  ;; WORKAROUND: allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map))


(provide 'config/langs/scala)
