;; -*- lexical-binding: t; -*-
(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Tmux jack-in

(defun ck/cider--tmux-session ()
  "tmux session name for the current project's nREPL server, or nil."
  (when-let (p-name (when (stringp (projectile-project-root))
                      (car (last (f-split (projectile-project-root))))))
    (concat "cider-" p-name)))

(defun ck/cider-kill-tmux ()
  "Disconnect CIDER and kill this project's tmux-hosted nREPL session."
  (interactive)
  (when-let* ((session (ck/cider--tmux-session)))
    (ignore-errors (cider-quit))
    (call-process "tmux" nil nil nil "kill-session" "-t" session)
    (message "Killed tmux session %S" session)))

(defun ck/cider--nrepl-ready-filter (proc chunk)
  "Append CHUNK to PROC's buffer; on the nREPL readiness line, connect
from the launcher's calling buffer, then kill PROC's buffer."
  (let ((buf (process-buffer proc)))
    (when (buffer-live-p buf)
      (with-current-buffer buf
        (let ((at-end (= (point) (process-mark proc))))
          (save-excursion
            (goto-char (process-mark proc))
            (insert chunk)
            (set-marker (process-mark proc) (point)))
          (when at-end (goto-char (process-mark proc))))
        (unless (process-get proc 'connected)
          (save-excursion
            (goto-char (point-min))
            (when (re-search-forward
                   "nREPL server started on port \\([0-9]+\\)" nil t)
              (process-put proc 'connected t)   ; tells the sentinel "clean exit"
              (let ((port   (string-to-number (match-string 1)))
                    (root   (process-get proc 'project-dir))
                    (caller (process-get proc 'caller-buffer))
                    (log    (process-get proc 'log-file)))
                (run-at-time
                 0 nil
                 (lambda ()
                   (when (process-live-p proc) (delete-process proc))
                   (let* ((win    (get-buffer-window buf))   ; the window the loading buffer occupies
                          (prev   cider-repl-pop-to-buffer-on-connect)
                          (params (list :host "127.0.0.1" :port port :project-dir root)))
                     ;; Stop CIDER from displaying the REPL itself; we place it deterministically.
                     (setq cider-repl-pop-to-buffer-on-connect nil)
                     (letrec ((place
                               (lambda ()
                                 (remove-hook 'cider-connected-hook place)
                                 (setq cider-repl-pop-to-buffer-on-connect prev)
                                 (let ((repl (cider-current-repl)))
                                   (if (and (window-live-p win) (buffer-live-p repl))
                                       (set-window-buffer win repl)        ; swap in place
                                     (when (buffer-live-p repl) (pop-to-buffer repl))))
                                 (when (buffer-live-p buf) (kill-buffer buf))
                                 (when (file-exists-p log) (ignore-errors (delete-file log)))
                                 (message "Connected to nREPL on port %d" port))))
                       (add-hook 'cider-connected-hook place))
                     (condition-case err            ; sync connect failure: undo, don't leak state
                         (if (buffer-live-p caller)
                             (with-current-buffer caller (cider-connect-clj params))
                           (cider-connect-clj params))
                       (error (setq cider-repl-pop-to-buffer-on-connect prev)
                              (remove-hook 'cider-connected-hook place)
                              (signal (car err) (cdr err)))))))))))))))

(defun ck/cider--nrepl-sentinel (proc _event)
  "Report failure if PROC exits before the nREPL server was ready."
  (unless (or (process-live-p proc)
              (process-get proc 'connected))
    (message "nREPL launcher (%s) exited before the server was ready - see %s"
             (process-get proc 'session) (process-buffer proc))))

(defvar-local ck/cider-cpuset nil
  "CPU list in taskset -c syntax (e.g. \"0-21\") to pin this project's nREPL JVM to.")
(put 'ck/cider-cpuset 'safe-local-variable #'stringp)

(defun ck/cider-jack-in-tmux ()
  "Launch CIDER's nREPL server in a detached tmux session.
A process buffer streams the server's output while waiting; the connect
fires off the server's own readiness line - no clock anywhere.

Refuses to run if this project's tmux session already exists; quit it
first with `ck/cider-nrepl-tmux-kill'."
  (interactive)
  (let* ((params  (cider--update-project-dir nil))
         (root    (plist-get params :project-dir))
         (session (ck/cider--tmux-session)))
    (unless (stringp root) (user-error "No project directory resolved here"))
    (when (zerop (call-process "tmux" nil nil nil "has-session" "-t" session))
      (user-error
       "tmux session %S is already running - quit it first with `M-x ck/cider-nrepl-tmux-kill'"
       session))
    (let* ((root    (expand-file-name root))
           (cmd (let ((base (plist-get (cider--update-jack-in-cmd params) :jack-in-cmd)))
                  (if ck/cider-cpuset
                      (concat "taskset -c " ck/cider-cpuset " " base)
                    base)))
           (log     (expand-file-name (format "nrepl-%s.log" session)
                                      temporary-file-directory))
           (buf     (get-buffer-create (format "*starting nrepl for %s*" session)))
           (caller  (current-buffer))
           (inner (format "direnv exec %s %s 2>&1 | tee %s"
                          (shell-quote-argument root)
                          cmd           ; stays UNQUOTED
                          (shell-quote-argument log)))
           (script  (format
                     (concat "tmux new-session -d -s %s -c %s %s || exit 1\n"
                             "p=$(tmux display-message -p -t %s '#{pane_pid}')\n"
                             "exec tail -n +1 -F --pid=\"$p\" %s")
                     (shell-quote-argument session)
                     (shell-quote-argument root)
                     (shell-quote-argument inner)
                     (shell-quote-argument session)
                     (shell-quote-argument log))))
      (when-let* ((old (get-buffer-process buf))) (delete-process old))
      (when (file-exists-p log) (delete-file log))
      (with-current-buffer buf
        (erase-buffer)
        (insert (format ";; Waiting for nREPL server in tmux session %S …\n"
                        session)
                ";; --- server output follows ---\n"))
      (let ((proc (start-process (format "nrepl-jackin-%s" session)
                                 buf "sh" "-c" script)))
        (process-put proc 'project-dir   root)
        (process-put proc 'caller-buffer caller)
        (process-put proc 'log-file      log)
        (process-put proc 'session       session)
        (set-process-filter   proc #'ck/cider--nrepl-ready-filter)
        (set-process-sentinel proc #'ck/cider--nrepl-sentinel)
        (set-process-query-on-exit-flag proc nil)
        (display-buffer buf)
        (message "nREPL booting in tmux %S - see %s" session buf)))))

(provide 'config/langs/clj/jack-in)
