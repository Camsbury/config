;; Functions for my emacs config

(require 'dash)

(defun eww-new ()
  "opens a new eww buffer"
  (interactive)
  (let ((url (read-from-minibuffer "Enter URL or keywords: ")))
    (switch-to-buffer (generate-new-buffer "eww"))
    (eww-mode)
    (eww url)))

(defun open-tmp-org ()
  "opens a temporary org file"
  (interactive)
  (evil-window-vsplit)
  (find-file "/tmp/notes.org"))

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
      (select-window (window-next-sibling)))
    (select-window my-window)))

(defun pretty-delete-window ()
  "Cleans up after itself after deleting current window"
  (interactive)
  (recentf-save-list)
  (delete-window)
  (prettify-windows))

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
  (prettify-windows)
  (windmove-right))

(defun spawn-project-file ()
  "Spawns a project file to the right"
  (interactive)
  (spawn-right)
  (project-find-file))

(defun spawn-recent-file ()
  "Spawns a project file to the right"
  (interactive)
  (spawn-right)
  (counsel-recentf))

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

(defun spawn-se-principles ()
  "Spawns the se principles file to the right"
  (interactive)
  (spawn-right)
  (find-file "~/projects/lxndr/ref/software_engineering.org"))

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

(provide 'functions-conf)

(defun nav-flash-line ()
  (interactive)
  (nav-flash-show))
