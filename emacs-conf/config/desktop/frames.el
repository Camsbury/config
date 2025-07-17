
(use-package posframe
  :config
  (setq posframe-mouse-banish-function #'posframe-mouse-banish-simple))

;; play with these!!
(comment
 (when (posframe-workable-p)
   (posframe-show " *my-posframe-buffer*"
                  :string "This is a test"
                  :position (point))))
