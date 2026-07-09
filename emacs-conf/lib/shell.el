;; -*- lexical-binding: t; -*-
;; Shell-command operations: fire-and-forget process spawns, async background
;; buffers, escaping, and nix-shell command building.  Pure library, no
;; wiring; NOT in the m-require boot chain, consumers `(require 'lib/shell)'.
;; Moved from config/desktop/commands.el (library/application seam).
(require 'prelude)
(require 'lib/utils)   ; ck/lisp-eval-sexp-at-point

(defun ck/-run-shell-command (command)
  "run a shell command"
  (start-process-shell-command command nil command))

(defun ck/run-shell-command-in-background (buff-name command)
  "runs a shell command async in a background buffer"
  (interactive "sBuffer name: \nsCommand: ")
  (async-shell-command
   command
   (generate-new-buffer-name (concat "*" buff-name "*"))))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escaper (matched-text)
    "Return replacement text for MATCHED-TEXT when shell-escaping.
See `shell-escape'."
    (cond
        ((string= matched-text "'")
            "\\\\'")
        ((string-match "\\(.\\)'" matched-text)
            (concat
                (match-string 1 matched-text)
                "\\\\'"))
        (t matched-text)))

;; derived from https://gist.github.com/PhilHudson/cf882c673599221d42b2
(defun rafd--shell-escape (string)
    "Make STRING safe to pass to a shell command."
    (->> string
      (replace-regexp-in-string "\n" " ")
      (replace-regexp-in-string
       ".?'"
       #'rafd--shell-escaper)))

(defun rafd--build-command (dir nix command)
  (concat
   (when dir
     (concat "cd " dir " && "))
   (if nix
       (concat "nix-shell --run '"
               (rafd--shell-escape command)
               "'"))))

(defun ck/run-async-from-desc ()
  "run a shell command async in a background buffer from a description in the
   form of an plist in the form of:
     :name    - name of the buffer
     :dir     - (optional) path to run command from
     :nix     - (optional) `t` if should run in nix-shell
     :command - content of the shell command to run"
  (interactive)
  (let* ((desc    (call-interactively #'ck/lisp-eval-sexp-at-point))
         (name    (plist-get desc :name))
         (dir     (plist-get desc :dir))
         (nix     (plist-get desc :nix))
         (command (plist-get desc :command)))
    (if (and name command)
        (async-shell-command
         (rafd--build-command dir nix command)
         (generate-new-buffer-name (concat "*" name "*")))
      (message "Pease call `ck/run-async-from-desc` with an plist containing the \
`:name` and `:command` keys."))))

(provide 'lib/shell)
