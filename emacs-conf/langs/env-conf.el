(use-package functions-conf)

(general-add-hook 'dotenv-mode-hook
                  (lambda ()
                    (set (make-local-variable 'comment-start) "#")))

(provide 'langs/env-conf)
