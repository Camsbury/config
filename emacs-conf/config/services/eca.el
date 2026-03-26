(require 'prelude)
(require 'core/bindings)

(use-package eca
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  :config
  (setq eca-chat-use-side-window nil)
  (setq eca-process--latest-server-version "0.112.0")

  (general-def 'normal eca-chat-mode-map
    [remap empty-mode-leader]     #'hydra-eca/body))

(defhydra hydra-eca (:exit t :columns 5)
  "eca-chat-mode"
  ("c" #'eca-chat-clear "Clear the chat")
  ("a" #'eca-chat-select-agent "Select agent")
  ("m" #'eca-chat-select-model "Select the model")
  ("v" #'eca-chat-select-variant "Select the variant"))



(provide 'config/services/eca)
