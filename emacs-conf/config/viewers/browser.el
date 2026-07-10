;; -*- lexical-binding: t; -*-
(require 'prelude)
;; general/hydra macros (general-add-hook, general-def, defhydra) expand from
;; here instead of depending on the core/bindings hub loading first.
(require 'core/definers)

;; eww's keymap, bound lazily before eww loads.
(declare-vars eww-mode-map)

(general-add-hook 'eww-mode-hook
                  'visual-line-mode
                  (lambda () (call-interactively (buffer-face-set 'hl-line))))

(defun ck/eww-new (buff-name)
  "opens a new eww buffer"
  (interactive "sBuffer name: ")
  (let ((url (read-from-minibuffer "Enter URL or keywords: ")))
    (switch-to-buffer (generate-new-buffer buff-name))
    (eww-mode)
    (eww url)))

(general-def 'normal eww-mode-map
 [remap ck/empty-mode-leader] #'hydra-eww/body)

(defhydra hydra-eww (:exit t)
  "eww-mode"
  ("h" #'eww-back-url "back")
  ("f" #'eww-toggle-fonts "monospace toggle")
  ("y" #'eww-copy-page-url "copy url"))


(provide 'config/viewers/browser)

;; Keybinding/hydra file: the eww-* commands and `hydra-eww/body' are runtime
;; forward-refs.  Suppress just the unresolved class; every other class stays
;; live.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
