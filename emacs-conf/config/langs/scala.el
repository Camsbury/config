(require 'prelude)

(use-package ammonite-term-repl)

(use-package scala-mode
  :interpreter
    ("scala" . scala-mode))

(use-package lsp-metals
  :after (lsp-mode)
  :custom
  (lsp-metals-server-args '("-J-Dmetals.allow-multiline-string-formatting=off"))
  :hook (scala-mode . lsp))

(use-package sbt-mode
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map))


(provide 'config/langs/scala)
