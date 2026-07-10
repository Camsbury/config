;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general owns this; declare so the load-time hook setup doesn't warn.
(declare-functions "general" general-add-hook)
(use-package prettier-js)
(general-add-hook 'html-mode-hook
                  (list 'flycheck-mode
                        'prettier-js-mode))

(provide 'config/langs/html)
