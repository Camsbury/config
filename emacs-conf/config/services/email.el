;; -*- lexical-binding: t; no-byte-compile: t; -*-
(use-package mu4e
  :bind ([remap mu4e] . mu4e)
  :config
  (setq
   mu4e-contexts
   `( ,(make-mu4e-context
        :name "Personal"
        :match-func
        (lambda (msg)
          (when msg
            (string-prefix-p "/personal" (mu4e-message-field msg :maildir))))
        :vars '((user-mail-address . "camsbury7@gmail.com")
                (user-full-name . "Cameron Kingsbury")
                (mu4e-sent-folder . "/personal/sent")
                (mu4e-drafts-folder . "/personal/drafts")
                (mu4e-trash-folder . "/personal/trash"))))
   message-send-mail-function 'message-send-mail-with-sendmail
   sendmail-program "/run/current-system/sw/bin/msmtp"
   mail-specify-envelope-from t
   mail-envelope-from 'header
   shr-color-visible-luminance-min 80)
  (with-eval-after-load 'mu4e
    (evil-collection-mu4e-setup)))


(provide 'config/services/email)
