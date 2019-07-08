(use-package package)

(-map (lambda (x) (add-to-list 'package-archives x t))
      '(("s-melpa" . "http://stable.melpa.org/packages/")
        ("melpa" . "http://melpa.milkbox.net/packages/")))

(provide 'package-conf)
