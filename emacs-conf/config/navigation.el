;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun xdg-open (l-name)
  "Open a link interactively"
  (interactive)
  (shell-command
   (concat "xdg-open \"" (alist-get l-name my-links) "\"")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nav Functions

(setq file-links
      '(:books         "~/Dropbox/lxndr/ref/books.org"
        :brain-dump    "~/Dropbox/lxndr/ref/dump.org"
        :frustrations  "~/Dropbox/lxndr/frustrations.org"
        :habits        "~/Dropbox/lxndr/habits.org"
        :journal       "~/Dropbox/lxndr/journal.org"
        :links         "~/Dropbox/lxndr/ref/links.org"
        :notes         "/tmp/notes.org"
        :questions     "~/Dropbox/lxndr/questions.org"
        :queue         "~/Dropbox/lxndr/queue.org"
        :raw           "~/Dropbox/lxndr/raw.org"
        :runs          "~/Dropbox/lxndr/ref/runs.org"
        :se-principles "~/Dropbox/lxndr/ref/software_engineering.org"
        :systems       "~/Dropbox/lxndr/systems.org"))

(defun open-file-link (file-key)
  "Open a file link interactively"
  (interactive)
  (->> file-key
    (plist-get file-links)
    find-file))

(defun open-new-tmp (arg)
  "Opens a new tmp file"
  (interactive "sFile name: ")
  (find-file (concat "/tmp/" arg)))

(defun open-project-summary ()
  "Opens the project's summary file"
  (interactive)
  (->> (f-relative (projectile-project-root) "~")
       (f-join "~/Dropbox/lxndr/summaries")
       (s-append "summary.org")
       (find-file)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Spawn Functions

(defun spawn-below ()
  "Spawns a window below"
  (interactive)
  (split-window-below)
  (windmove-down))

(defun spawn-right ()
  "Spawns a window to the right"
  (interactive)
  (split-window-right)
  (windmove-right))

(defun spawn-file-link (file-key)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (open-file-link file-key))

(defun spawnify (f)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (call-interactively f))

(defun spawn-new (arg)
  "Spawns a new fundamental buffer"
  (interactive "sBuffer name: ")
  (spawn-right)
  (switch-to-buffer (generate-new-buffer-name arg)))

(defun spawn-bindings ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file (concat (getenv "CONFIG_PATH") "/core/bindings.el")))

(provide 'config/navigation)
