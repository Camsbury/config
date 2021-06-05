(use-package keychain-environment
  :config (keychain-refresh-environment))
(use-package direnv
  :config (direnv-mode))

(defun latest-loadpath ()
  "Gets the latest loadpath (useful after a rebuild switch)"
  (interactive)
  (let* ((edeps-root
          (->> "cmacs-load-path"
               (shell-command-to-string)
               (replace-regexp-in-string "\n$" "")))
         (base-path
          (-remove
           (lambda (path) (s-match "emacs-packages-deps" path))
           load-path))
         (edeps
          (cons edeps-root
                (f-directories edeps-root nil t))))
    (setq load-path (-concat base-path edeps))))


(provide 'config/env)
