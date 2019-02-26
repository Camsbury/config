;; Functions for my emacs config

(require 'dash)
(require 'etymology-of-word)

(defun eww-new ()
  "opens a new eww buffer"
  (interactive)
  (let ((url (read-from-minibuffer "Enter URL or keywords: ")))
    (switch-to-buffer (generate-new-buffer "eww"))
    (eww-mode)
    (eww url)))

(defun set-window-width (count)
  "Set the selected window's width."
  (adjust-window-trailing-edge (selected-window) (- count (window-width)) t))

(defun prettify-windows ()
  "Set the windows all to have 81 chars of length"
  (interactive)
  (let ((my-window (selected-window)))
    (select-window (frame-first-window))
    (while (window-next-sibling)
      (set-window-width 81)
      (evil-beginning-of-line)
      (select-window (window-next-sibling)))
    (select-window my-window)))

(defun pretty-delete-window ()
  "Cleans up after itself after deleting current window"
  (interactive)
  (recentf-save-list)
  (delete-window)
  (prettify-windows))

(defun open-new-fundamental (arg)
  "Opens a new fundamental mode file"
  (interactive "sBuffer name: ")
  (switch-to-buffer (generate-new-buffer arg)))

(defun open-se-principles ()
  "Opens the SE principles file"
  (interactive)
  (find-file "~/projects/lxndr/ref/software_engineering.org"))

(defun open-tmp-org ()
  "opens a temporary org file"
  (interactive)
  (find-file "/tmp/notes.org"))

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
      (call-interactively #'global-command-log-mode)
      (clm/toggle-command-log-buffer))))



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

(defun spawn-bindings ()
  "Spawns the bindings file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/bindings-conf.el"))

(defun spawn-config ()
  "Spawns the config file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/config.el"))

(defun spawn-functions ()
  "Spawns the functions file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.emacs.d/config/functions-conf.el"))

(defun spawn-zshrc ()
  "Spawns the zshrc file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.zshrc"))

(defun spawn-xmonad ()
  "Spawns the XMonad conf file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/.xmonad/xmonad.hs"))

(defun spawn-emacs-nix ()
  "Spawns the emacs nix file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/projects/nix_dots/emacs.nix"))

(defun spawn-clubhouse ()
  "Clubhouse tix"
  (interactive)
  (spawn-right)
  (find-file "~/clubhouse.org"))

(defun spawn-se-principles ()
  "Spawns the se principles file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/projects/lxndr/ref/software_engineering.org"))

(defun spawn-project-tasks ()
  "Spawns the project's tasks file to the right"
  (interactive)
  (let ((path (->> (projectile-project-root)
                  f-filename
                  (f-join "~/projects/lxndr/tasks")
                  (s-append ".org"))))
       (spawn-right)
       (find-file path)))

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
  (call-interactively 'widen)
  (call-interactively 'text-scale-set)
  (call-interactively 'text-scale-decrease)
  (prettify-windows))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; grfn utils

(defmacro comment (&rest _body)
  "Comment out one or more s-expressions"
  nil)

(defun inc (x) "Returns x + 1" (+ 1 x))
(defun dec (x) "Returns x - 1" (- x 1))


;;
;; Text editing utils
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

(provide 'functions-conf)
