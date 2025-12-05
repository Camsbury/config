(require 'config/modes/utils)
(require 'config/modes/center-buffer-mode)
(define-minor-mode prettify-mode
  "Make buffers clean themselves up if this mode is on"
  :lighter " prettify"
  :global nil)

(defun prettify-windows ()
  "Set the windows all to have 86 chars of length"
  (interactive)

  (center-buffer--center-when-single)
  (with-selected-window (frame-first-window)
    (dolist (w (window-list))
      (with-selected-window w
        (when
            (minor-mode-active-p 'prettify-mode)
          (set-window-width w 86))))))

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
