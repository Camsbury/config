;; Functions for my emacs config

(defun spawn-right ()
  "Spawns a window to the right"
  (interactive)
  (split-window-right)
  (windmove-right))

(provide 'functions)
