(use-package dotenv-mode)

(general-add-hook 'dotenv-mode-hook
                  (lambda ()
                    (set (make-local-variable 'comment-start) "#")))

(provide 'langs/env-conf)
