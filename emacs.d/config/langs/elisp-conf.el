(use-package bindings-conf)
(use-package dash)
(use-package dash-functional)
(use-package f)
(use-package functions-conf)
(use-package s)

(eval-after-load 'dash '(dash-enable-font-lock))
(general-add-hook 'emacs-lisp-mode-hook
                  (list 'paredit-mode
                        'lispyville-mode))


(general-def 'normal emacs-lisp-mode-map
 [remap empty-mode-leader] #'hydra-elisp/body)

(defun elisp-narrow-defun ()
  "Narrows to the current defun"
  (interactive)
  (save-mark-and-excursion
    (mark-defun)
    (call-interactively 'narrow-and-zoom-in)))

(defhydra hydra-elisp (:exit t)
  "elisp-mode"
 ("l" #'eval-buffer        "eval buffer")
 ("o" #'elisp-narrow-defun "focus on def"))

(provide 'langs/elisp-conf)
