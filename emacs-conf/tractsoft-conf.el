(defun migrate-tractsoft-db ()
  "migrate the db"
  (interactive)
  (shell-command
   (concat
    "cd ~/projects/tractsoft/shared-db &&"
    "nix-shell ../shell.nix --run 'lein run -m db.tool migrate'")))

(provide 'tractsoft-conf)
