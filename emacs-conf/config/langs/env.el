;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general owns this; declare so the load-time hook setup doesn't warn.
(declare-functions "general" general-add-hook)
(use-package dotenv-mode)

(general-add-hook 'dotenv-mode-hook
                  (lambda ()
                    (set (make-local-variable 'comment-start) "#")))

(provide 'config/langs/env)
