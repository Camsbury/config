(require 'prelude)
(require 'core/bindings)

(use-package eca
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  :config
  (setq eca-chat-use-side-window nil)

  (general-def 'normal eca-chat-mode-map
    [remap empty-mode-leader]     #'hydra-eca/body))

(defhydra hydra-eca (:exit t :columns 5)
  "eca-chat-mode"
  ("c" #'eca-chat-clear "Clear the chat")
  ("b" #'eca-chat-select-behavior "Cycle behavior")
  ("a" #'eca-chat-tool-call-accept-all "Accept all chat tool calls")
  ("A" #'eca-chat-tool-call-accept-all-and-remember "Accept all chat tool calls (and remember)")
  ("m" #'eca-chat-select-model "Select the model"))



(provide 'config/services/eca)
