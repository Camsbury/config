(use-package nov)
(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

(setq nov-text-width 80)

;; make this thing monospaced
(setq nov-variable-pitch nil)

(general-add-hook 'nov-mode-hook
                  'evil-mode)

(general-def 'normal nov-mode-map
 [remap empty-mode-leader] #'hydra-nov/body)

(defhydra hydra-nov (:exit t)
  "nov-mode"
  ("t" #'nov-goto-toc          "table of contents")
  ("h" #'nov-previous-document "back")
  ("l" #'nov-next-document     "next"))

(provide 'viewers/epub)
