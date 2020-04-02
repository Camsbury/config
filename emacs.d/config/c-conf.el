(setq c-basic-offset 2)
(setq c-basic-indent 2)

(general-def 'normal c-mode-map
 [remap empty-mode-leader] #'hydra-c/body)

(general-add-hook 'c-mode-hook
  (list
    (lambda ()
      (progn
        (setq company-backends (delete 'company-clang company-backends))
        (add-to-list 'company-backends 'company-c-headers)))
    'flycheck-mode
    'eldoc-mode
    'rainbow-delimiters-mode))

(defhydra hydra-c (:exit t)
  "c-mode"
  ("m" #'man "man page"))

(provide 'c-conf)
