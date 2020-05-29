(require 'bindings-conf)
(require 'functions-conf)
(require 'magit)

(general-add-hook 'magit-mode-hook
                  (list 'evil-magit-init))

(defun github-clone (user repo)
  "clones a repo from github to the obvious path"
  (interactive "sUser name: \nsRepo name:")
  (start-process-shell-command
   (concat "clone " user "/" repo)
   nil
   (concat "mkdir -p ~/projects/" user " && "
    "cd ~/projects/" user " && "
    "git clone git@github.com:" user "/" repo ".git")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add smart upstream

(define-suffix-command magit-push-smart-upstream (args)
  "Push the current branch to its smart upstream branch."
  :if 'magit-get-current-branch
  :description 'magit-push--upstream-description
  (interactive (list (magit-push-arguments)))
  (let ((branch (or (magit-get-current-branch)
                     (user-error "No branch is checked out"))))
    (run-hooks 'magit-credential-hook)
    (magit-run-git-async "push" "-v" args "-u" "origin" branch)))

(transient-suffix-put 'magit-push "u" :key "U")
(transient-append-suffix 'magit-push "U"
  '("u" "Smart Upstream" magit-push-smart-upstream))
(setq transient-default-level 7)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keybindings

(general-define-key
 :states  'normal
 :keymaps 'magit-blame-mode-map
 "q" #'magit-blame-quit)

(general-define-key
 :states  'normal
 :keymaps 'magit-status-mode-map
 [remap magit-section-backward-sibling] #'hydra-left-leader/body
 [remap magit-section-forward-sibling]  #'hydra-right-leader/body
 [remap magit-diff-show-or-scroll-up]   #'hydra-leader/body
 [remap magit-section-backward]         #'evil-window-up
 [remap magit-section-forward]          #'evil-window-down
 [remap indent-new-comment-line]        #'magit-section-forward
 [remap kill-sentence]                  #'magit-section-backward)

(general-define-key
 :keymaps 'git-timemachine-mode-map
 [remap evil-record-macro] #'git-timemachine-quit
 [remap evil-window-up]    #'git-timemachine-show-previous-revision
 [remap evil-window-down]  #'git-timemachine-show-next-revision)

(general-define-key
 :states  'normal
 :keymaps 'magit-diff-mode-map
 "<RET>"                         #'magit-diff-visit-file-other-window
 "zz"                            #'evil-scroll-line-to-center
 "zt"                            #'evil-scroll-line-to-top
 "zb"                            #'evil-scroll-line-to-bottom
 "L"                             #'evil-window-bottom
 "H"                             #'evil-window-top
 [remap magit-section-backward]  #'evil-window-up
 [remap magit-section-forward]   #'evil-window-down
 [remap indent-new-comment-line] #'magit-section-forward
 [remap kill-sentence]           #'magit-section-backward
 [remap scroll-up]               #'hydra-leader-body)


(provide 'git-conf)
