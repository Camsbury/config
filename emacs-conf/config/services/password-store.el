;; -*- lexical-binding: t; -*-
(require 'prelude)

;; Set buffer-locally below; owned by undo-tree (config/text.el).
(defvar undo-tree-auto-save-history)

(declare-functions "password-store" password-store-edit)

(defun ck/pass-insert-in-buffer (entry)
  "Create ENTRY by writing it in a buffer instead of the minibuffer.
`pass edit' on a new name opens an empty temp file here through
with-editor.  Write the secret on the first line and any `key: value'
fields below it, save, then \\`C-c C-c' to encrypt."
  (interactive (list (read-string "New entry: ")))
  (password-store-edit entry))

(use-package pass
  :commands (pass)
  :config
  (define-key pass-mode-map [remap pass-insert] #'ck/pass-insert-in-buffer))

(defun ck/keep-secret-buffer-off-disk ()
  "Stop Emacs writing plaintext copies of a decrypted secret to disk.
A buffer visiting a `pass' temp file (under /dev/shm) or an EasyPG
.gpg file holds decrypted text.  Auto-save and undo-tree history
would copy that text into ~/.cache/emacs/, outside the encryption."
  (when (and buffer-file-name
             (or (string-prefix-p "/dev/shm/" buffer-file-name)
                 (string-suffix-p ".gpg" buffer-file-name)))
    (auto-save-mode -1)
    (setq-local undo-tree-auto-save-history nil)))

(add-hook 'find-file-hook #'ck/keep-secret-buffer-off-disk)

(provide 'config/services/password-store)
