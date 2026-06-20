;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/env)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org roam

(use-package org-roam
  :config
  (customize-set-variable
   'org-roam-directory
   (concat cmacs-share-path "/org-roam"))
  (customize-set-variable
   'org-roam-capture-templates
   '(("n" "default" plain "%?"
      :target (file+head "${slug}.org.gpg"
                         "#+title: ${title}\n")
      :unnarrowed t)))
  (customize-set-variable 'epa-file-select-keys 1)
  (setq epa-file-encrypt-to '("camsbury7@gmail.com"))
  (add-hook 'exwm-init-hook
            (lambda () (run-with-idle-timer 1 nil #'org-roam-db-autosync-mode)))
  ;; (org-roam-db-autosync-mode)
  )

(defun gtd--visit-roam-node (node-name)
  (interactive)
  (let ((node (org-roam-node-from-title-or-alias node-name)))
    (when node
      (org-roam-node-visit node))))

(use-package org-roam-dailies
  :after (org-roam)
  :config
  (customize-set-variable
   'org-roam-dailies-directory
   "daily/")
  (customize-set-variable
   'org-roam-dailies-capture-templates
   '(("d" "default" entry
      "* %?"
      :target (file+head "%<%Y-%m-%d>.org.gpg"
                         "#+title: %<%Y-%m-%d>\n")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org roam ui

(use-package websocket
  :after (org-roam))

(use-package org-roam-ui
  :hook (after-init . org-roam-ui-mode)
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t))

(provide 'config/langs/org/roam)
