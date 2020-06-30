(require 'bindings-conf)

(general-def 'normal go-mode-map
 [remap empty-mode-leader] #'hydra-go/body
 )

(setq gofmt-command "goimports")

(general-add-hook
 'go-mode-hook
 `(#'flycheck-mode
   #'company-mode
   ,(lambda () (add-hook 'before-save-hook 'gofmt-before-save))))


(defhydra hydra-go (:exit t)
  "go-mode"
  ("d" #'godef-jump "jump to def"))


(provide 'go-conf)
