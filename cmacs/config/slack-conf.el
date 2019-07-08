(use-package slack)
(use-package alert)
(use-package emojify)
(use-package company-emoji)
(use-package private-conf)

;; (setq slack-buffer-emojify t) ;; if you want to enable emoji, default nil
(setq slack-prefer-current-team t)
(if (string-equal system-type "gnu/linux")
    (setq alert-default-style 'notifier))
(if (string-equal system-type "darwin")
    (setq alert-default-style 'osx-notifier))
(setq slack-buffer-function #'switch-to-buffer)

(general-add-hook 'slack-mode-hook
                  (slack-register-team
                   :name "Urbint"
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
