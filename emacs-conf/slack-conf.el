(use-package slack)
(use-package alert)
(use-package emojify)
(use-package company-emoji)

(setq slack-buffer-emojify t)
(setq slack-prefer-current-team t)
(if (string-equal system-type "gnu/linux")
    (setq alert-default-style 'notifier))
(setq slack-buffer-function #'switch-to-buffer)

(general-add-hook 'slack-mode-hook
                  (slack-register-team
                   :name "Example"
                   :default t
                   :client-id slack-client-id-private
                   :client-secret slack-client-secret-private
                   :token slack-client-token-private
                   :subscribed-channels
                   '(dev
                     crossbores
                     inspections
                     dev-capture
                     general
                     music
                     engineering
                     ml)
                   :full-and-display-names t))
(slack-start)

(provide 'slack-conf)
