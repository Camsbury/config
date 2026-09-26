;; -*- lexical-binding: t; -*-
(require 'prelude)

(defvar undo-tree-auto-save-history)
(defvar pass-buffer-name)

(declare-functions "password-store" password-store-edit)
(declare-functions "pass" pass-edit pass-update-buffer)
(declare-functions "evil" evil-set-initial-state evil-insert-state)

(defun ck/pass--refresh-list (proc _event)
  "Refresh the pass list once PROC has exited."
  (unless (process-live-p proc)
    (when-let* ((buf (get-buffer pass-buffer-name)))
      (with-current-buffer buf
        (pass-update-buffer)))))

(defun ck/pass--refresh-after (fn &rest args)
  "Call FN with ARGS, refreshing the pass list when its process exits."
  (let ((before (process-list)))
    (apply fn args)
    (dolist (proc (seq-difference (process-list) before))
      (add-function :after (process-sentinel proc)
                    #'ck/pass--refresh-list))))

(defun ck/pass-insert-in-buffer (entry)
  "Create ENTRY by writing it in a buffer."
  (interactive (list (read-string "New entry: ")))
  (ck/pass--refresh-after #'password-store-edit entry))

(defun ck/pass-edit-at-point ()
  "Edit the entry at point."
  (interactive)
  (ck/pass--refresh-after #'call-interactively #'pass-edit))

(use-package pass
  :commands (pass)
  :config
  (evil-set-initial-state 'pass-mode 'emacs)
  (define-key pass-mode-map [remap pass-insert] #'ck/pass-insert-in-buffer)
  (define-key pass-mode-map [remap pass-edit] #'ck/pass-edit-at-point))

(defun ck/pass-edit-finish ()
  "Save and encrypt the entry."
  (interactive)
  (save-buffer)
  (server-edit))

(defun ck/pass-edit-cancel ()
  "Discard the edit, deleting the temp file so pass saves nothing."
  (interactive)
  (set-buffer-modified-p nil)
  (when (file-exists-p buffer-file-name)
    (delete-file buffer-file-name))
  (server-edit))

(defvar-keymap ck/pass-edit-mode-map
  "C-c C-c"                                #'ck/pass-edit-finish
  "C-c C-k"                                #'ck/pass-edit-cancel
  "<remap> <server-edit>"                  #'ck/pass-edit-finish
  "<remap> <evil-save-and-close>"          #'ck/pass-edit-finish
  "<remap> <evil-save-modified-and-close>" #'ck/pass-edit-finish
  "<remap> <evil-quit>"                    #'ck/pass-edit-cancel)

(define-minor-mode ck/pass-edit-mode
  "Keys for finishing or discarding a `pass edit' buffer."
  :lighter " Pass"
  (setq-local header-line-format
              (when ck/pass-edit-mode
                "C-c C-c / :wq encrypt    C-c C-k / :q! discard")))

(defun ck/pass-edit-setup ()
  "Enable `ck/pass-edit-mode' in a `pass edit' temp file."
  (when (and buffer-file-name
             (string-prefix-p "/dev/shm/pass." buffer-file-name))
    (ck/pass-edit-mode 1)
    (when (fboundp 'evil-insert-state)
      (evil-insert-state))))

(add-hook 'find-file-hook #'ck/pass-edit-setup)

(defun ck/keep-secret-buffer-off-disk ()
  "Disable auto-save and undo history in buffers holding decrypted text."
  (when (and buffer-file-name
             (or (string-prefix-p "/dev/shm/" buffer-file-name)
                 (string-suffix-p ".gpg" buffer-file-name)))
    (auto-save-mode -1)
    (setq-local undo-tree-auto-save-history nil)))

(add-hook 'find-file-hook #'ck/keep-secret-buffer-off-disk)

(provide 'config/services/password-store)
