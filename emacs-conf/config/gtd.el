(require 'prelude)
(require 'hydra)
(require 'core/env)
(require 'config/langs/org)
(require 'config/modes/utils)

(use-package pomidor
  :config
  (setq pomidor-sound-tick nil
        pomidor-sound-tack nil
        pomidor-sound-overwork (concat cmacs-share-path "/chime.wav")
        pomidor-sound-break-over (concat cmacs-share-path "/chime.wav")
        pomidor-long-break-seconds (* 20 60)
        pomidor-update-interval 15
        pomidor-confirm-end-break nil
        pomidor-play-sound-file
        (lambda (file)
          (start-process "my-pomidor-play-sound"
                         nil
                         "aplay"
                         file)))
  (add-to-list 'evil-emacs-state-modes 'pomidor-mode)

  (defface pomidor-work-mode-line-face
    '((t (:foreground "yellow" :weight bold)))
    "Face for work state in the Pomidor mode line."
    :group 'pomidor)

  (defface pomidor-break-mode-line-face
    '((t (:foreground "green" :weight bold)))
    "Face for break state in the Pomidor mode line."
    :group 'pomidor)

  (defface pomidor-overwork-mode-line-face
    '((t (:foreground "red" :weight bold)))
    "Face for overwork state in the Pomidor mode line."
    :group 'pomidor)

  ;; Variable holding the modeline status string
  (defvar pomidor-mode-line-string ""
    "String displaying current Pomidor status in the mode line.")

  (defun pomidor-update-modeline ()
    "Update `pomidor-mode-line-string' based on the current Pomidor state.
    Shows a hammer emoji for work, a relaxing emoji for break,
    and a warning emoji for overwork."
    (let* ((work (or (pomidor-work-duration) (seconds-to-time 0)))
           (over (pomidor-overwork-duration))
           (brk (pomidor-break-duration))
           (brk-icon (if (pomidor-should-long-break-p)
                         "🏖️"
                       "🧘"))
           (on-hold pomidor--system-on-hold-p)
           (time-str (cond
                      (on-hold "💤 Pomos paused")
                      (brk (format (concat brk-icon " %s") (pomidor--format-duration brk)))
                      (over (format "🔥️ %s" (pomidor--format-duration over)))
                      (work (format "🍅 %s" (pomidor--format-duration work)))
                      (t "Idle")))
           (face (cond
                  (on-hold 'pomidor-break-mode-line-face)
                  (brk 'pomidor-break-mode-line-face)
                  (over 'pomidor-overwork-mode-line-face)
                  (work 'pomidor-work-mode-line-face)
                  (t 'default)))
           (base-text (propertize (format " %s " time-str) 'face face))
           (click-map (let ((map (make-sparse-keymap)))
                        (define-key map [mode-line down-mouse-1]
                                    (lambda (event)
                                      (interactive "e")
                                      (switch-to-buffer (pomidor--get-buffer-create))))
                        map)))
      (setq pomidor-mode-line-string
            (propertize base-text
                        'face face
                        'help-echo "Pomodoro\nmouse-1: open *pomidor* buffer"
                        'mouse-face 'mode-line-highlight
                        'local-map click-map))
      (force-mode-line-update)))

  ;; Hook the modeline update into Pomidor's update cycle.
  (advice-add 'pomidor--update :after #'pomidor-update-modeline)
  (advice-add 'pomidor-hold :after #'pomidor-update-modeline)

  ;; Ensure the Pomidor status string appears in the global mode line.
  (add-to-list 'global-mode-string  '(:eval pomidor-mode-line-string) t)

  :hook (pomidor-mode . (lambda ()
                          (display-line-numbers-mode -1) ; Emacs 26.1+
                          (setq left-fringe-width 0 right-fringe-width 0)
                          (setq left-margin-width 2 right-margin-width 0)
                          ;; force fringe update
                          (set-window-buffer nil (current-buffer)))))

(defun pomidor-quit ()
  "Turn off Pomidor."
  (interactive)
  (kill-buffer (pomidor--get-buffer-create))
  (setq pomidor-mode-line-string ""))

(defun pomodoro-dwim ()
  (interactive)
  (if (pomidor-running-p)
      (call-interactively #'pomidor-break)
    (if pomidor--system-on-hold-p
          (call-interactively #'pomidor-unhold)
        (let ((b (current-buffer)))
          (call-interactively #'pomidor)
          (switch-to-buffer b)))))

(defun pomodoro-hold-dwim ()
  (interactive)
  (if pomidor--system-on-hold-p
      (call-interactively #'pomidor-unhold)
    (call-interactively #'pomidor-hold)))

(setq org-tags-exclude-from-inheritance '("project")
      org-agenda-files `(,(concat cmacs-share-path "/org-roam/projects.org.gpg")
                         ,(concat cmacs-share-path "/org-roam/habit_tracker.org.gpg"))
      org-habit-graph-column 60
      org-agenda-start-on-weekday nil
      org-agenda-custom-commands
      '(("d" "Default Agenda"
         ((tags-todo "c@digital"
                     ((org-agenda-skip-function
                       '(org-agenda-skip-entry-if 'scheduled 'deadline 'timestamp))))
          (tags-todo "c@physical"
                     ((org-agenda-skip-function
                       '(org-agenda-skip-entry-if 'scheduled 'deadline 'timestamp))))
          (agenda ""
                  ((org-agenda-span 'day)
                   (org-deadline-warning-days 0)))))
        ("c" "Calendar"
         ((agenda ""
                  ((org-agenda-span 'month)
                   (org-agenda-files `(,(concat cmacs-share-path "/org-roam/events.org.gpg")))
                   (org-deadline-warning-days 0)))))))

(defun gtd--show-hidden-habits ()
  (interactive)
  (let ((current-prefix-arg t))
    (call-interactively #'org-habit-toggle-display-in-agenda)))

(defun gtd--build-tags (tags selected fn)
  (ivy-read
   "Tag: "
   (append tags '("DONE"))
   :preselect "DONE"
   :action
   (lambda (tag)
     (if (string= "DONE" tag)
         (funcall fn selected)
       (let* ((selected (cons tag selected))
              (tags     (remove tag tags)))
         (gtd--build-tags tags selected fn))))))

(defun gtd--tagged-next-actions-view
    (tags)
  (org-tags-view t (s-join "|" tags)))

(defun gtd-projects ()
  (interactive)
  (org-tags-view nil "project"))

(defun gtd--tags->next-actions
    (filter-regex)
  (let* ((filter-fn (if filter-regex
                        (lambda (x) (s-matches? filter-regex x))
                      #'identity))
         (tags (->>
                (with-current-buffer
                    (find-file-noselect (car org-agenda-files))
                  (org-get-buffer-tags))
                (-map #'car)
                (-filter filter-fn))))
    (gtd--build-tags tags '() #'gtd--tagged-next-actions-view)))

(defun gtd-tags->next-actions ()
  (interactive)
  (gtd--tags->next-actions nil))

(defun gtd-contexts->next-actions ()
  (interactive)
  (gtd--tags->next-actions "c@"))

(defun gtd-projects->next-actions ()
  (interactive)
  (gtd--tags->next-actions "p@"))

(defun gtd-topics->next-actions ()
  (interactive)
  (gtd--tags->next-actions "t@"))

(defun gtd-search-mark-done ()
  (interactive)
  (let ((tasks (ht-create)))
    (org-map-entries
     (lambda ()
       (when (org-get-todo-state)
           (let ((pom (point)))
             (ht-set!
              tasks
              (buffer-substring pom (line-end-position))
              (copy-marker pom)))))
     nil
     'agenda)
    (ivy-read
     "Completed Task: "
     (ht-keys tasks)
     :action
     (lambda (task)
       (let ((m (ht-get tasks task)))
         (save-excursion
           (with-current-buffer (marker-buffer m)
             (goto-char m)
             (org-todo)
             ;; FIXME: this is too fast for some reason for the habit hooks
             (save-buffer))))))))

(defun gtd--get-org-mode-link-label (str)
  "Return the label of an org-mode link, or the string itself if it's not a link."
  (if (string-match "\\[\\[.*\\]\\[\\(.*\\)\\]\\]" str)
      (match-string 1 str)
    str))

(defun gtd-jump-to-project ()
  (interactive)
  (let ((projects (ht-create)))
    (org-map-entries
     (lambda ()
       (let ((pom (point)))
         (ht-set!
          projects
          (substring-no-properties
           (gtd--get-org-mode-link-label
            (org-get-heading t t)))
          (copy-marker pom))))
     "project"
     'agenda)
    (ivy-read
     "Project: "
     (ht-keys projects)
     :action
     (lambda (p)
       (let ((m (ht-get projects p)))
         (switch-to-buffer (marker-buffer m))
         (goto-char m)
         (evil-scroll-line-to-center)
         (org-show-subtree))))))

(defun gtd-open-graph ()
  (interactive)
  (if (minor-mode-active-p 'org-roam-ui-mode)
      (call-interactively #'org-roam-ui-open)
    (progn
      (call-interactively #'org-roam-ui-mode)
      (call-interactively #'org-roam-ui-open))))

(defhydra hydra-gtd (:exit t :columns 5)
  "set register"
  ;; ("SPC" #'toggle-org-alerts        "toggle org alerts")
  ("SPC" #'pomodoro-dwim            "pomodoro dwim")
  ;; ("P" #'gtd-projects->next-actions "projects->next-actions")
  ("a" #'pomodoro-hold-dwim         "pomodoro hold dwim")
  ("P" #'gtd-projects               "projects list")
  ("c" #'gtd-contexts->next-actions "contexts->next-actions")
  ("e" #'gtd-search-mark-done       "search and mark done")
  ;; ("l" #'org-agenda-list            "calendar")
  ("l" (lambda ()
         (interactive)
         (org-agenda nil "d")) "next actions")
  ("n" #'gtd-topics->next-actions   "topics->next-actions")
  ("o" (lambda ()
         (interactive)
         (spawn-right)
         (find-file (concat cmacs-config-path "/config/gtd.el")))
   "gtd.el")
  ("O" #'pomidor-quit               "end pomodoro")
  ("p" #'gtd-jump-to-project        "jump to project")
  ("r" #'org-roam-buffer-toggle     "toggle roam info")
  ("t" #'gtd-tags->next-actions     "tags->next-actions")
  ("g" #'gtd-open-graph             "open org graph")

  ("q" nil "quit"))

(advice-add
 #'org-agenda-todo
 :after
 (lambda (&rest _)
   (org-save-all-org-buffers)))

(general-define-key :keymaps 'org-agenda-mode-map
                    "H" #'org-habit-toggle-display-in-agenda
                    "K" #'gtd--show-hidden-habits
                    "h" #'evil-backward-char
                    "j" #'org-agenda-next-line
                    "k" #'org-agenda-previous-line
                    "l" #'evil-forward-char
                    "o" #'org-agenda)

(provide 'config/gtd)
