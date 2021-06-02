;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun xdg-open (l-name)
  "Open a link interactively"
  (interactive)
  (shell-command
   (concat "xdg-open \"" (alist-get l-name my-links) "\"")))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nav Functions

(defmacro open-file (name path &optional desc)
  `(defun ,(intern (concat "open-" (symbol-name `,name))) ()
     ,desc
     (interactive)
     (find-file ,path)))

(open-file
 se-principles
 "~/Dropbox/lxndr/ref/software_engineering.org"
 "Opens the SE principles file")

(open-file
 tmp-org
 "/tmp/notes.org"
 "opens a temporary org file")

(open-file
 daybook
 "~/Dropbox/lxndr/daybook.org"
 "Opens daybook")

(open-file
 books
 "~/Dropbox/lxndr/ref/books.org"
 "Opens my book notes")

(open-file
 runs
 "~/Dropbox/lxndr/ref/runs.org"
 "Opens my runs file")

(open-file
 links
 "~/Dropbox/lxndr/ref/links.org"
 "Opens my links file")

(open-file
 journal
 "~/Dropbox/lxndr/journal.org"
 "Opens my journal")

(open-file
 dump
 "~/Dropbox/lxndr/ref/dump.org"
 "Opens my brain dump")

(open-file
 habits
 "~/Dropbox/lxndr/habits.org"
 "Opens my habits tracker")

(open-file
 queue
 "~/Dropbox/lxndr/queue.org"
 "Opens my queue")

(open-file
 work
 "~/Dropbox/lxndr/work.org"
 "Opens my work org")

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
  (windmove-right)
  (prettify-windows))

(defun spawnify (f)
  "Spawn a window to the right before calling a function"
  (interactive)
  (split-window-right)
  (windmove-right)
  (call-interactively f)
  (prettify-windows))

(defun spawn-new (arg)
  "Spawns a new fundamental buffer"
  (interactive "sBuffer name: ")
  (spawn-right)
  (switch-to-buffer (generate-new-buffer-name arg)))

(defun spawn-functions ()
  "Spawns the functions file to the right"
  (interactive)
  (spawn-right)
  (find-file (concat (getenv "CONFIG_PATH") "/core/commands.el")))

(defun spawn-bindings ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file (concat (getenv "CONFIG_PATH") "/core/bindings.el")))

(defun spawn-config ()
  "Spawns the config file to the right"
  (interactive)
  (spawn-right)
  (find-file (concat (getenv "CONFIG_PATH") "/core.el")))

(provide 'core/navigation)
