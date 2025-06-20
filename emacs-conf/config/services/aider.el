(use-package aidermacs
  :bind (("C-c a" . aidermacs-transient-menu))
  :custom
  (aidermacs-default-chat-mode 'architect)
  (aidermacs-default-model "ollama/devstral-small"))

(provide 'config/services/aider)
