(require 'bindings-conf)

(general-add-hook 'eww-mode-hook
                  'visual-line-mode
                  (lambda () (call-interactively (buffer-face-set 'hl-line))))

(general-def 'normal eww-mode-map
 [remap empty-mode-leader] #'hydra-eww/body
 )

(defhydra hydra-eww (:exit t)
  "eww-mode"
  ("h" #'eww-back-url "back")
  ("y" #'eww-copy-page-url "copy url"))


(provide 'browser-conf)
