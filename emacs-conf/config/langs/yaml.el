;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general owns this; declare so the load-time hook setup doesn't warn.
(declare-functions "general" general-add-hook)
(use-package yaml-mode
  :init (general-add-hook 'yaml-mode-hook
                          (list 'display-line-numbers-mode)))

(provide 'config/langs/yaml)
