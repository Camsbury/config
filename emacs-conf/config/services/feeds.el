(require 'prelude)
(require 'core/env)

(use-package elfeed)
(use-package elfeed-score
  :after (elfeed)
  :init
  (customize-set-variable 'elfeed-score-serde-score-file (concat cmacs-share-path "/feeds.score"))
  :config
  (evil-set-initial-state 'elfeed-show-mode 'emacs)
  (evil-set-initial-state 'elfeed-search-mode 'emacs)
  (elfeed-score-enable)
  (define-key elfeed-search-mode-map "." elfeed-score-map))
(use-package elfeed-org
  :after (elfeed)
  :config
  (elfeed-org)
  (setq rmh-elfeed-org-files `(,(concat cmacs-share-path "/feeds.org"))))

(provide 'config/services/feeds)
