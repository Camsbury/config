;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Running Shell Commands in Buffers

(defun run-shell-command-in-background (buff-name command)
  "runs a shell command async in a background buffer"
  (interactive "sBuffer name: \nsCommand: ")
  (async-shell-command
   command
   (generate-new-buffer (concat "*" buff-name "*"))))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escaper (matched-text)
    "Return replacement text for MATCHED-TEXT when shell-escaping.
See `shell-escape'."
    (cond
        ((string= matched-text "'")
            "\\\\'")
        ((string-match "\\(.\\)'" matched-text)
            (concat
                (match-string 1 matched-text)
                "\\\\'"))
        (t matched-text)))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escape (string)
    "Make STRING safe to pass to a shell command."
    (->> string
      (replace-regexp-in-string "\n" " ")
      (replace-regexp-in-string
       ".?'"
       #'rafd--shell-escaper)))


(defun rafd--build-command (dir nix command)
  (concat
   (when dir
     (concat "cd " dir " && "))
   (if nix
       (concat "nix-shell --run '"
               (rafd--shell-escape command)
               "'"))))

(defun run-async-from-desc ()
  "run a shell command async in a background buffer from a description in the
   form of an plist in the form of:
     :name    - name of the buffer
     :dir     - (optional) path to run command from
     :nix     - (optional) `t` if should run in nix-shell
     :command - content of the shell command to run"
  (interactive)
  (let* ((desc    (call-interactively #'lisp-eval-sexp-at-point))
         (name    (plist-get desc :name))
         (dir     (plist-get desc :dir))
         (nix     (plist-get desc :nix))
         (command (plist-get desc :command)))
    (if (and name command)
        (async-shell-command
         (rafd--build-command dir nix command)
         (generate-new-buffer (concat "*" name "*")))
      (message "Pease call `run-async-from-desc` with an plist containing the \
`:name` and `:command` keys."))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eww-new (buff-name)
  "opens a new eww buffer"
  (interactive "sBuffer name: ")
  (let ((url (read-from-minibuffer "Enter URL or keywords: ")))
    (switch-to-buffer (generate-new-buffer buff-name))
    (eww-mode)
    (eww url)))

(defun latest-loadpath ()
  "Gets the latest loadpath (useful after a rebuild switch)"
  (interactive)
  (let* ((edeps-root
          (->> "cmacs-load-path"
               (shell-command-to-string)
               (replace-regexp-in-string "\n$" "")))
         (base-path
          (-remove
           (lambda (path) (s-match "emacs-packages-deps" path))
           load-path))
         (edeps
          (cons edeps-root
                (f-directories edeps-root nil t))))
    (setq load-path (-concat base-path edeps))))

(defun xdg-open (l-name)
  "Open a link interactively"
  (interactive)
  (shell-command
   (concat "xdg-open \"" (alist-get l-name my-links) "\"")))

(defun git-init ()
  "initialize git"
  (interactive)
  (shell-command "git init && touch .gitignore"))

(defun lorri-init ()
  "initialize lorri"
  (interactive)
  (shell-command "lorri init && direnv allow"))

(defun lorri-watch ()
  "lorri watcher for nix changes"
  (interactive)
  (async-shell-command "lorri watch"))

(defun set-window-width (count)
  "Set the selected window's width."
  (adjust-window-trailing-edge (selected-window) (- count (window-width)) t))

(defun prettify-windows ()
  "Set the windows all to have 81 chars of length"
  (interactive)
  (let ((my-window (selected-window)))
    (select-window (frame-first-window))
    (while (window-next-sibling)
      (set-window-width 85)
      (evil-beginning-of-line)
      (select-window (window-next-sibling)))
    (select-window my-window)))

(defun pretty-delete-window ()
  "Cleans up after itself after deleting current window"
  (interactive)
  (recentf-save-list)
  (delete-window)
  (prettify-windows))

(defun evil-save-as (arg)
  "Save buffer as"
  (interactive "sFile name: ")
  (evil-save arg))

(defun toggle-command-logging ()
  "Toggle command logging"
  (interactive)
  (if (bound-and-true-p command-log-mode)
      (call-interactively #'global-command-log-mode)
    (progn
      (call-interactively #'command-log-mode)
      (call-interactively #'global-command-log-mode)
      (clm/toggle-command-log-buffer))))

(defun copy-buffer-path ()
  "Copies the path of the current buffer"
  (interactive)
  (kill-new (buffer-file-name)))

(defun clean-quit-emacs ()
  "Saves stuff before quitting"
  (interactive)
  (recentf-save-list)
  (call-interactively #'save-buffers-kill-emacs))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Git Utils

(defun reset-repo-master (repo-name output-buffer)
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

(defun reset-working-repos ()
  "reset all working repos to origin/master"
  (interactive)
  (-each working-repos (lambda (repo)
                         (reset-repo-master
                          repo
                          (generate-new-buffer "*Reset Working Repos*")))))


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
  (switch-to-buffer (generate-new-buffer arg)))

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Test Jumping

(defun jump-to-test-haskell ()
  "Jump from a haskell module to a test."
  (let ((filename (->> buffer-file-name
                       (s-replace "/src/" "/test/")
                       (s-replace ".hs" "Test.hs"))))
    (make-directory (f-dirname filename) t)
    (find-file filename)))

(defun jump-from-test-haskell ()
  "Jump from a test to a haskell module."
  (let ((filename (->> buffer-file-name
                       (s-replace "/test/" "/src/")
                       (s-replace "Test.hs" ".hs"))))
    (make-directory (f-dirname filename) t)
    (find-file filename)))

(defun toggle-test-haskell ()
  "Toggle test and source in Haskell."
  (if (s-contains? "/src/" buffer-file-name)
      (jump-to-test-haskell)
    (jump-from-test-haskell)))

(defun toggle-test ()
  "Toggle between test and source."
  (interactive)
  (when (s-contains? ".hs" buffer-file-name)
    (toggle-test-haskell)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Utility Functions

(defun increment-number-at-point ()
  (interactive)
  (skip-chars-backward "0-9")
  (or (looking-at "[0-9]+")
      (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))

(defun nav-flash-line ()
  (interactive)
  (nav-flash-show))

(defun empty-mode-leader ()
  (interactive)
  (message "current mode hydra is unbound"))

(defun empty-visual-mode-leader ()
  (interactive)
  (message "current visual mode hydra is unbound"))

(defun narrow-and-zoom-in ()
  "Narrow to selection and zoom in"
  (interactive)
  (call-interactively 'narrow-to-region)
  (call-interactively 'text-scale-increase)
  (call-interactively 'text-scale-increase)
  (call-interactively 'text-scale-increase)
  (set-window-width 130))

(defun widen-and-zoom-out ()
  "Widen the buffer and set zoom to normal"
  (interactive)
  (save-mark-and-excursion (call-interactively 'widen)
   (call-interactively 'text-scale-set)
   (call-interactively 'text-scale-decrease)
   (prettify-windows)))

(defun minor-mode-active-p (minor-mode)
  "Check if the passed minor-mode is active"
  (not
   (null
    (--filter
     (eq it minor-mode)
     (--filter
      (and
       (boundp it)
       (symbol-value it))
      minor-mode-list)))))

(defun org-append-link ()
  "Append link instead of replacing current point"
  (interactive)
  (insert " ")
  (call-interactively #'org-insert-link))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; grfn utils
;;

;; Reading strings

(defun get-char (&optional point)
  "Get the character at the given `point' (defaulting to the current point),
without properties"
  (let ((point (or point (point))))
    (buffer-substring-no-properties point (+ 1 point))))

(defun get-line (&optional lineno)
  "Read the line number `lineno', or the current line if `lineno' is nil, and
return it as a string stripped of all text properties"
  (let ((current-line (line-number-at-pos)))
    (if (or (not lineno)
            (= current-line lineno))
        (thing-at-point 'line t)
      (save-mark-and-excursion
       (line-move (- lineno (line-number-at-pos)))
       (thing-at-point 'line t)))))

(defun get-line-point ()
  "Get the position in the current line of the point"
  (- (point) (line-beginning-position)))

;; Moving in the file

(defun goto-line-char (pt)
  "Moves the point to the given position expressed as an offset from the start
of the line"
  (goto-char (+ (line-beginning-position) pt)))

(defun goto-eol ()
  "Moves to the end of the current line"
  (goto-char (line-end-position)))

(defun goto-regex-on-line (regex)
  "Moves the point to the first occurrence of `regex' on the current line.
Returns nil if the regex did not match, non-nil otherwise"
  (when-let ((current-line (get-line))
             (line-char (string-match regex current-line)))
    (goto-line-char line-char)))

(defun goto-regex-on-line-r (regex)
  "Moves the point to the *last* occurrence of `regex' on the current line.
Returns nil if the regex did not match, non-nil otherwise"
  (when-let ((current-line (get-line))
             (modified-regex (concat ".*\\(" regex "\\)"))
             (_ (string-match modified-regex current-line))
             (match-start (match-beginning 1)))
    (goto-line-char match-start)))

(comment
 (progn
   (string-match (rx (and (zero-or-more anything)
                          (group "foo" "foo")))
                 "foofoofoo")
   (match-beginning 1)))

;; Changing file contents

(defun delete-line ()
  "Remove the line at the current point"
  (delete-region (line-beginning-position)
                 (inc (line-end-position))))

(defmacro modify-then-indent (&rest body)
  "Modify text in the buffer according to body, then re-indent from where the
  cursor started to where the cursor ended up, then return the cursor to where
  it started."
  `(let ((beg (line-beginning-position))
         (orig-line-char (- (point) (line-beginning-position))))
     (atomic-change-group
       (save-mark-and-excursion
        ,@body
        (evil-indent beg (+ (line-end-position) 1))))
     (goto-line-char orig-line-char)))

(provide 'core/commands)
