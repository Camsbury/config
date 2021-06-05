(use-package dotenv-mode)

(general-add-hook 'dotenv-mode-hook
                  (lambda ()
                    (set (make-local-variable 'comment-start) "#")))

(provide 'config/langs/env)
