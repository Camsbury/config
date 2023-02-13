(require 'config/modes/utils)
(define-minor-mode prettify-mode
  "Make buffers clean themselves up if this mode is on"
  :lighter " prettify"
  :global nil)

(defun prettify-windows ()
  "Set the windows all to have 81 chars of length"
  (interactive)

  (with-selected-window (frame-first-window)
    (dolist (w (window-list))
      (with-selected-window w
        (when
            (minor-mode-active-p 'prettify-mode)
          (set-window-width w 85))))))

;; non-prog modes
(general-add-hook
 '(nxml-mode-hook
   haskell-cabal-mode-hook)
 #'prettify-mode)

;; when to run
(general-add-hook
 '(find-file-hook after-delete-window-hook after-split-window-hook)
 #'prettify-windows)

(provide 'config/modes/prettify-mode)
