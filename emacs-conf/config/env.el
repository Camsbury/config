;; -*- lexical-binding: t; -*-
(use-package keychain-environment
  :config (keychain-refresh-environment))
(use-package direnv
  :config (direnv-mode))

;;; Echo-area truncation for chatty messages --------------------------------
;;
;; direnv `message's a single-line summary of every environment change; a big
;; nix devshell delta is long enough to wrap across several lines and grow the
;; echo area / minibuffer on every buffer switch.  We want the full delta kept
;; in *Messages* (readable in full there) but only a one-line version shown in
;; the echo area.  `set-message-functions' (Emacs 29+, a list run in order)
;; governs echo-area DISPLAY only: *Messages* logging already happened in the
;; C core by the time these run, so a keyed entry here shortens the echo
;; without touching the log.  Prepending keeps us ahead of the default
;; `set-minibuffer-message'.

(defcustom ck/echo-truncate-prefixes '("direnv: ")
  "Message prefixes whose echo-area display is capped to one line.
A message starting with any of these is shortened to fit one frame-width
line in the echo area only; the full text is still logged to *Messages*.
Any non-matching message passes through untouched."
  :type '(repeat string)
  :group 'cmacs)

(defun ck/echo--direnv-compact (msg)
  "Reformat a direnv summary MSG to `direnv: N changes (path)'.
direnv formats its summary as \"direnv: <vars> (<path>)\"; when that var
list is long we keep the trailing path (which dir loaded, the useful
part) and collapse the vars to a count.  Returns the compact string, or
nil when MSG is not a direnv summary with a trailing parenthesised path."
  (when (string-match "\\`direnv: \\(.*\\) (\\([^()]*\\))\\'" msg)
    ;; Bind both groups BEFORE `split-string' (its own regexp match would
    ;; clobber the global match data and lose the path).
    (let* ((vars (match-string 1 msg))
           (path (match-string 2 msg))
           (n (length (split-string vars "[ \t]+" t))))
      (format "direnv: %d change%s (%s)" n (if (= n 1) "" "s") path))))

(defun ck/echo-truncate-message (msg)
  "Shorten a chatty prefixed MSG for the echo area only.
For `set-message-functions': when MSG starts with a
`ck/echo-truncate-prefixes' entry AND is long enough to wrap past one
line, return a one-line version (a `direnv: N changes (path)' reformat
when possible, else a frame-width truncation ending in \"...\").  Returns
nil otherwise so the message passes through unchanged.  *Messages* keeps
the full text either way."
  (when (and msg
             (seq-some (lambda (p) (string-prefix-p p msg))
                       ck/echo-truncate-prefixes)
             (>= (string-width msg) (frame-width)))
    (let ((short (or (ck/echo--direnv-compact msg)
                     (car (split-string msg "\n")))))
      (truncate-string-to-width short (max 0 (- (frame-width) 2))
                                nil nil "..."))))

(add-to-list 'set-message-functions #'ck/echo-truncate-message)

(defun ck/latest-loadpath ()
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

(setq safe-local-variable-directories
      '("/home/camsbury/projects/Camsbury/"
        "/home/camsbury/projects/dynamic-alpha/"))


(provide 'config/env)
