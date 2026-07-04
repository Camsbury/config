;; -*- lexical-binding: t; -*-
(require 'config/modes/utils)
(require 'config/modes/center-buffer-mode)
(define-minor-mode prettify-mode
  "Make buffers clean themselves up if this mode is on"
  :lighter " prettify"
  :global nil)

(defun ck/prettify-windows ()
  "Set the windows all to have 86 chars of length"
  (interactive)

  (center-buffer--center-when-single)
  (with-selected-window (frame-first-window)
    (dolist (w (window-list))
      (with-selected-window w
        (when
            (ck/minor-mode-active-p 'prettify-mode)
          (ck/set-window-width w 86))))))

;; non-prog modes
;; NOTE: `general-add-hook' is a bare `add-hook' wrapper with no normalization,
;; so every entry must be an actual hook variable (`-hook' suffix).  A plain
;; mode symbol like `eca-chat-mode' would attach to a symbol nothing runs.
(general-add-hook
 '(eca-chat-mode-hook
   nxml-mode-hook
   haskell-cabal-mode-hook)
 #'prettify-mode)

;; when to run
(general-add-hook
 '(find-file-hook after-delete-window-hook after-split-window-hook)
 #'ck/prettify-windows)

(provide 'config/modes/prettify-mode)
