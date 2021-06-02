(general-add-hook 'eww-mode-hook
                  'visual-line-mode
                  (lambda () (call-interactively (buffer-face-set 'hl-line))))

(defun eww-new (buff-name)
  "opens a new eww buffer"
  (interactive "sBuffer name: ")
  (let ((url (read-from-minibuffer "Enter URL or keywords: ")))
    (switch-to-buffer (generate-new-buffer buff-name))
    (eww-mode)
    (eww url)))

(general-def 'normal eww-mode-map
 [remap empty-mode-leader] #'hydra-eww/body)

(defhydra hydra-eww (:exit t)
  "eww-mode"
  ("h" #'eww-back-url "back")
  ("f" #'eww-toggle-fonts "monospace toggle")
  ("y" #'eww-copy-page-url "copy url"))


(provide 'viewers/browser)
