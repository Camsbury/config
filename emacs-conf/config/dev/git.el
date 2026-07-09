;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general/hydra macros (general-define-key, defhydra) come from here, so they
;; expand in isolation instead of depending on the core/bindings hub loading
;; first.  The leader hydras this file remaps to (hydra-leader/body etc.) are
;; runtime forward-refs, suppressed by the file-local at the bottom.
(require 'core/keys-base)

;; magit's status keymap, referenced by difftastic's `:bind :map' before magit
;; loads.
(declare-vars magit-status-mode-map)

(use-package git-timemachine)

;; NOTE: this needs to be before magit so it runs before
;; evil-collection-magit-setup
(use-package forge
  :after (magit)
  :config
  (setq auth-sources '("~/.authinfo.gpg")))
(use-package magit
  :init
  ;; NOTE: deal with seq issues temporarily (probably can remove later)
  (defun seq-keep (function sequence)
    "Apply FUNCTION to SEQUENCE and return the list of all the non-nil results."
    (delq nil (seq-map function sequence)))
  :config
  (with-eval-after-load 'magit
    (evil-collection-magit-setup)))
(use-package magit-todos
  :after (magit)
  :config
  (customize-set-variable
   'magit-todos-keywords
   '("TODO" "FIXME" "NOTE" "CLEAN" "USEIT" "IMPL"))
  (customize-set-variable
   'magit-todos-ignored-keywords
   '("DONE"))
  (magit-todos-mode))
(use-package difftastic
  :after (magit)
  :bind (:map magit-status-mode-map
              ("D" . difftastic-magit-diff)
              ("S" . difftastic-magit-show)))
;; (use-package magit-difftastic
;;   :after (magit)
;;   :config (magit-difftastic-mode +1))

;; (let ((token (getenv "GH_NOTIF_TOKEN")))
;;   (when token
;;     (use-package github-notifier
;;       :init
;;       (customize-set-variable 'github-notifier-token token)
;;       :config
;;       (github-notifier-mode 1))))
;; USEIT
(use-package browse-at-remote)

(defun ck/github-clone (user repo)
  "clones a repo from github to the obvious path"
  (interactive "sUser name: \nsRepo name: ")
  (call-interactively #'ck/gpg-keychain)
  (call-interactively #'ck/ssh-keychain)
  (start-process-shell-command
   (concat "clone " user "/" repo)
   nil
   (concat "mkdir -p ~/projects/" user " && "
           "cd ~/projects/" user " && "
           "git clone git@github.com:" user "/" repo ".git")))

(defun ck/kill-magit-buffer ()
  "Kills a magit buffer"
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively #'magit-mode-bury-buffer)))

;; USEIT
(defun ck/gitgrep-history (regex)
  "grep through git history"
  (interactive "s")
  (shell-command-to-string
   (concat
    "git log -S " regex " --pickaxe-regex -p --branches --all | rg " regex)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Multi Repo Utils

(defvar working-repos nil
  "List of sibling repo names (dirs next to the current repo) that
`ck/reset-working-repos' hard-resets to origin/master.  Set it per host;
nil means the command is a no-op instead of a void-variable error.")

(defun ck/reset-repo-master (repo-name output-buffer)
  "reset the repo's master branch to origin/master"
  (async-shell-command
   (concat
    "cd \"$(git rev-parse --show-toplevel)\" &&"
    "cd .. &&"
    "cd " repo-name " &&"
    "git add . &&"
    "git stash &&"
    "git checkout master &&"
    "git fetch &&"
    "git reset --hard origin/master")
   output-buffer))

(defun ck/reset-working-repos ()
  "reset all working repos to origin/master"
  (interactive)
  (-each working-repos (lambda (repo)
                         (ck/reset-repo-master
                          repo
                          (generate-new-buffer-name
                           (concat "*Reset " repo " to origin/master*"))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Add smart upstream

(transient-define-suffix magit-push-smart-upstream (args)
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
;; `transient-default-level' now lives in config/transient-defaults.el so it
;; applies to every transient, not just magit's.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Keybindings

(defhydra hydra-git (:exit t :columns 5)
  "git"
  ("b" #'magit-blame                       "magit blame")
  ("r" #'browse-at-remote                  "browse at remote")
  ("s" #'magit-status                      "magit status")
  ("t" #'git-timemachine-toggle            "git time machine")
  ("l" #'ck/github-clone                      "github clone")
  ("q" nil))

(general-define-key
 [remap magit-mode-bury-buffer] #'ck/kill-magit-buffer)

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
 [remap scroll-up]               #'hydra-leader/body)


(provide 'config/dev/git)

;; Keybinding/hydra file: it forward-references the leader hydras
;; (hydra-leader/body, hydra-left-leader/body, ...) defined in the core/bindings
;; hub and magit/git-timemachine commands, all invoked only at runtime.
;; Suppress just the unresolved class; keep every other class live.  Removing
;; these forward-ref edges from the DAG is what dissolves the
;; core/bindings <-> dev/git cycle.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
