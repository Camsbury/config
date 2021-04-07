(defun random-uuid ()
  "Returns a random UUID V4"
  (interactive)
  (-> "nix-shell --pure \\
       -p babashka \\
       --run 'bb \"(str (java.util.UUID/randomUUID))\"'"
      (shell-command-to-string)
      (kill-new)))

(provide 'core/utils)
