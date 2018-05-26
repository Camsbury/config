(require 'bindings-conf)

(setq org-directory (expand-file-name "~/projects/lxndr/")
      org-capture-templates '(("n" "Push onto Task Stack" entry
                               (file+headline "~/projects/lxndr/task_stack.org" "Tasks") "* [ ] %i%?"))
      org-agenda-files '("~projects/lxndr/queue.org")
      org-refile-targets '(("~/projects/lxndr/queue.org" :maxlevel . 3)
                           ("~/projects/lxndr/ref.org" :level . 1))
      org-archive-location (concat "~/projects/lxndr/archive/" (format-time-string "%Y-%m") ".org::")
      org-todo-keywords '((sequence "[ ]" "[x]")))

(general-emacs-define-key org-capture-mode-map
  [remap evil-save-and-close]          'org-capture-finalize
  [remap evil-save-modified-and-close] 'org-capture-finalize
  [remap evil-quit]                    'org-capture-kill)

(general-emacs-define-key org-mode-map
  [remap evil-ret]                     'org-todo)

(my-mode-leader-def
 :states  'normal
 :keymaps 'org-mode-map
 "a" 'org-archive-subtree
 "r" 'org-refile
 )

(general-add-hook 'org-mode-hook
  (list 'org-bullets-mode 'org-indent-mode 'visual-line-mode))

(provide 'org-conf)
