;; -*- lexical-binding: t; -*-
;;; Checks for the cam-pair launcher, `ck/eca-pair-open'.
;;
;; Drives the command against the in-memory upstream fake, so no ECA server,
;; session, or chat is needed.  The one criterion not checked here is the live
;; layout under EXWM (actor in the selected window, critic in a right band,
;; no stray chat window afterwards); that is the owner's check in a real
;; Emacs.  What IS checked here is the behavior that layout rests on: the
;; display action used for each buffer, and that chat creation leaves the
;; window configuration alone.

(require 'ert)
(require 'cl-lib)
(require 'config/services/eca/pair)
;; Load the in-memory fake adapter AFTER pair.el pulled in the real one, so
;; its `ck/eca-upstream-' definitions win.
(load (expand-file-name
       "eca-upstream-fake"
       (file-name-directory (or load-file-name buffer-file-name))))

;; `ck/display-buffer-right-band' lives in config/navigation.el, which this
;; batch run does not load (it pulls the whole completion stack in with it).
;; Stand in for it with a plain split so `display-buffer' has something to
;; call; the real band action is exercised in the live Emacs.
(unless (fboundp 'ck/display-buffer-right-band)
  (defun ck/display-buffer-right-band (buffer alist)
    (when-let* ((window (ignore-errors
                          (split-window (selected-window) nil 'right))))
      (window--display-buffer buffer window 'window alist))))

(defvar ck/eca-pair-test--messages nil
  "Messages the command emitted during one check, newest first.")

(defmacro ck/eca-pair-test--in-workspace (root &rest body)
  "Run BODY with ROOT as the workspace root, capturing every message."
  (declare (indent 1) (debug t))
  `(let ((ck/eca-pair-test--messages nil))
     (ck/eca-upstream-fake-reset)
     ;; One window showing a known buffer: the layout checks below need a
     ;; starting point no earlier test can have moved.
     (delete-other-windows)
     (switch-to-buffer (get-buffer-create "*ck-eca-pair-test-origin*"))
     (cl-letf (((symbol-function 'ck/eca-pair--workspace-root)
                (lambda () ,root))
               ((symbol-function 'message)
                (lambda (fmt &rest args)
                  (push (if fmt (apply #'format fmt args) "")
                        ck/eca-pair-test--messages)
                  nil)))
       ,@body)))

(defun ck/eca-pair-test--said-p (regexp)
  "Non-nil when one captured message matches REGEXP."
  (and (seq-find (lambda (line) (string-match-p regexp line))
                 ck/eca-pair-test--messages)
       t))

(defun ck/eca-pair-test--session (root)
  "Return the fake session the command made for ROOT."
  (ck/eca-upstream-session-for-root root))

(ert-deftest ck/eca-pair-open-creates-both-chats-and-enters-them ()
  (let ((root "/tmp/ck-eca-pair-fresh/"))
    (ck/eca-pair-test--in-workspace root
      (ck/eca-pair-open)
      (let* ((session (ck/eca-pair-test--session root))
             (critic (ck/eca-pair--chat-for-agent session "pair-critic"))
             (actor (ck/eca-pair--chat-for-agent session "pair-actor"))
             (sent (ck/eca-upstream-fake-sent-prompts)))
        (should (= 2 (length (ck/eca-upstream-session-chats session))))
        (should (buffer-live-p critic))
        (should (buffer-live-p actor))
        (should-not (eq critic actor))
        ;; Both entered, critic first.
        (should (equal (list (cons critic "/cam-pair:enter")
                             (cons actor "/cam-pair:enter"))
                       sent))
        ;; Point ends in the actor's prompt, not at the end of its buffer.
        (with-current-buffer actor
          (should (= (point) (ck/eca-upstream-prompt-field-start-point)))
          (should (< (point) (point-max))))))))

(ert-deftest ck/eca-pair-open-restores-the-session-default-agent ()
  (let ((root "/tmp/ck-eca-pair-default-agent/"))
    (ck/eca-pair-test--in-workspace root
      (let ((session (ck/eca-upstream-start-session nil root nil)))
        (ck/eca-upstream-set-session-default-agent session "dev")
        (ck/eca-pair-open)
        (should (equal "dev"
                       (ck/eca-upstream-session-default-agent session)))
        (let ((actor (ck/eca-pair--chat-for-agent session "pair-actor")))
          (should (equal "pair-actor" (ck/eca-upstream-chat-agent actor)))
          ;; Selecting an agent really does move the default, so the check
          ;; above is not passing on an absent side effect.
          (ck/eca-upstream-chat-set-agent session "probe" actor)
          (should (equal "probe"
                         (ck/eca-upstream-session-default-agent session))))))))

(ert-deftest ck/eca-pair-open-run-twice-adds-no-chat-and-no-prompt ()
  (let ((root "/tmp/ck-eca-pair-twice/"))
    (ck/eca-pair-test--in-workspace root
      (ck/eca-pair-open)
      (let* ((session (ck/eca-pair-test--session root))
             (chats (ck/eca-upstream-session-chats session)))
        (should (= 2 (length chats)))
        (should (= 2 (length (ck/eca-upstream-fake-sent-prompts))))
        ;; A chat that was just entered is running its turn.
        (dolist (buffer chats)
          (ck/eca-upstream-fake-set-chat-status buffer 'running))
        (ck/eca-pair-open)
        (should (equal chats (ck/eca-upstream-session-chats session)))
        (should (= 2 (length (ck/eca-upstream-fake-sent-prompts))))))))

(ert-deftest ck/eca-pair-open-enters-the-idle-chat-only ()
  (let ((root "/tmp/ck-eca-pair-idle/"))
    (ck/eca-pair-test--in-workspace root
      (ck/eca-pair-open)
      (let* ((session (ck/eca-pair-test--session root))
             (critic (ck/eca-pair--chat-for-agent session "pair-critic"))
             (actor (ck/eca-pair--chat-for-agent session "pair-actor")))
        (ck/eca-upstream-fake-set-chat-status critic 'waiting-approval)
        (ck/eca-upstream-fake-set-chat-status actor 'idle)
        (should (eq 'waiting-approval (ck/eca-upstream-chat-status critic)))
        (should (eq 'idle (ck/eca-upstream-chat-status actor)))
        (ck/eca-pair-open)
        (let ((sent (ck/eca-upstream-fake-sent-prompts)))
          (should (= 3 (length sent)))
          ;; The third prompt is the second one the actor got; the critic,
          ;; waiting on the owner, got nothing more.
          (should (eq actor (car (nth 2 sent))))
          (should (= 1 (seq-count (lambda (entry) (eq critic (car entry)))
                                  sent))))))))

(ert-deftest ck/eca-pair-open-places-the-actor-then-the-critic ()
  (let ((root "/tmp/ck-eca-pair-layout/")
        (placements nil))
    (ck/eca-pair-test--in-workspace root
      (cl-letf (((symbol-function 'display-buffer)
                 (lambda (buffer &rest _)
                   (push (cons buffer display-buffer-overriding-action)
                         placements)
                   nil)))
        (ck/eca-pair-open))
      (setq placements (nreverse placements))
      (let* ((session (ck/eca-pair-test--session root))
             (critic (ck/eca-pair--chat-for-agent session "pair-critic"))
             (actor (ck/eca-pair--chat-for-agent session "pair-actor")))
        ;; The launcher's own two placements are the last two: starting the
        ;; session displays a chat of its own first, with no overriding
        ;; action, and that call lands in this list too.
        (should (equal (list (cons actor '(display-buffer-same-window))
                             (cons critic '(ck/display-buffer-right-band)))
                       (last placements 2)))))))

(ert-deftest ck/eca-pair-open-adopts-the-chat-the-start-opened ()
  "Starting a session opens a chat and takes a window before the launcher
runs (`eca-chat-open' from eca.el:425 and eca.el:341).  That chat must
become one of the two pair chats, and the window must go back."
  (let ((root "/tmp/ck-eca-pair-start-chat/"))
    (ck/eca-pair-test--in-workspace root
      (let ((origin (selected-window)))
        (ck/eca-pair-open)
        (let* ((session (ck/eca-pair-test--session root))
               (chats (ck/eca-upstream-session-chats session))
               (critic (ck/eca-pair--chat-for-agent session "pair-critic"))
               (actor (ck/eca-pair--chat-for-agent session "pair-actor")))
          ;; Exactly two chats, and both of them are pair chats: the one the
          ;; start opened was adopted, not left beside a fresh pair.
          (should (= 2 (length chats)))
          (should (equal '("pair-actor" "pair-critic")
                         (sort (mapcar #'ck/eca-upstream-chat-agent chats)
                               #'string<)))
          ;; The actor sits in the window the command was run from, and that
          ;; window is the selected one afterwards.
          (should (window-live-p origin))
          (should (eq actor (window-buffer origin)))
          (should (eq origin (selected-window)))
          ;; The critic is shown, elsewhere, and nothing else shows a chat.
          (should (window-live-p (get-buffer-window critic)))
          (should-not (eq origin (get-buffer-window critic)))
          (dolist (window (window-list))
            (when (memq (window-buffer window) chats)
              (should (or (eq window origin)
                          (eq critic (window-buffer window)))))))))))

(ert-deftest ck/eca-pair-open-reopens-a-pair-chat-rather-than-adding-one ()
  "With both pair chats alive but the session's last chat gone, upstream
would create a third one on the way in (eca-chat.el:5787-5789).  The
launch points the session at a pair chat first, so it does not."
  (let ((root "/tmp/ck-eca-pair-last-chat/"))
    (ck/eca-pair-test--in-workspace root
      (ck/eca-pair-open)
      (let* ((session (ck/eca-pair-test--session root))
             (chats (ck/eca-upstream-session-chats session)))
        (should (= 2 (length chats)))
        (ck/eca-upstream-fake-set-last-chat session nil)
        (ck/eca-pair-open)
        (should (equal chats (ck/eca-upstream-session-chats session)))))))

(ert-deftest ck/eca-pair-open-refuses-a-starting-session ()
  "A session that is still initializing never runs the ready callback
\(eca.el:427), so the launch must say so instead of doing nothing."
  (let ((root "/tmp/ck-eca-pair-starting/"))
    (ck/eca-pair-test--in-workspace root
      (let* ((session (ck/eca-upstream-start-session nil root nil))
             (chats (ck/eca-upstream-session-chats session)))
        (ck/eca-upstream-fake-set-session-status session 'starting)
        (should-not (ck/eca-pair-open))
        (should (equal chats (ck/eca-upstream-session-chats session)))
        (should-not (ck/eca-upstream-fake-sent-prompts))
        (should (ck/eca-pair-test--said-p
                 (regexp-quote "ECA session is starting")))))))

(defun ck/eca-pair-test--chat-trap ()
  "Return a `display-buffer-alist' that captures fake chat buffers.
Stands for `ck/eca-display-reuse-same-workspace-window', the ECA entry
the launcher exists to bypass: it takes any chat `display-buffer' has
not already placed, here into a window of its own so a test can see it
fire."
  (list (cons (lambda (name _action)
                (string-prefix-p "<eca-chat[fake]" name))
              (list (lambda (buffer alist)
                      (when-let* ((window (ignore-errors
                                            (split-window
                                             (frame-root-window) nil 'below))))
                        (window--display-buffer buffer window 'window
                                                alist)))))))

(ert-deftest ck/eca-pair-place-chats-avoids-a-dedicated-window ()
  "A dedicated window refuses `display-buffer-same-window', and
`display-buffer' then falls through to `display-buffer-alist', where the
ECA entry puts the actor wherever that entry wants.  The actor has to
land in a window the launcher picked instead."
  (let ((root "/tmp/ck-eca-pair-dedicated/"))
    (ck/eca-pair-test--in-workspace root
      (let* ((session (ck/eca-upstream-start-session nil root nil))
             (actor (ck/eca-pair--claim-chat session "pair-actor"))
             (critic (ck/eca-pair--claim-chat session "pair-critic")))
        (delete-other-windows)
        (switch-to-buffer "*ck-eca-pair-test-origin*")
        (let* ((origin (selected-window))
               (usable (split-window origin nil 'right)))
          (set-window-buffer usable (get-buffer-create "*ck-eca-pair-other*"))
          (set-window-dedicated-p origin t)
          (unwind-protect
              (let ((display-buffer-alist (ck/eca-pair-test--chat-trap)))
                (ck/eca-pair--place-chats actor critic origin)
                (should (eq usable (get-buffer-window actor)))
                ;; The dedicated window kept its own buffer.
                (should-not (eq actor (window-buffer origin))))
            (set-window-dedicated-p origin nil)))))))

(ert-deftest ck/eca-pair-creating-a-chat-leaves-the-windows-alone ()
  (let ((root "/tmp/ck-eca-pair-windows/"))
    (ck/eca-pair-test--in-workspace root
      (let* ((session (ck/eca-upstream-start-session nil root nil))
             (before (window-buffer (selected-window))))
        ;; The fake's creation switches the window, as upstream's does;
        ;; without that this check would pass on nothing.
        (ck/eca-upstream-new-chat session)
        (should-not (eq before (window-buffer (selected-window))))
        (switch-to-buffer before)
        (let ((buffer (ck/eca-pair--claim-chat session "pair-actor")))
          (should (buffer-live-p buffer))
          (should (eq before (window-buffer (selected-window)))))))))

(ert-deftest ck/eca-pair-open-without-a-workspace-root-creates-nothing ()
  (ck/eca-pair-test--in-workspace nil
    (should-not (ck/eca-pair-open))
    (should-not ck/eca-upstream-fake--sessions)
    (should-not (ck/eca-upstream-fake-sent-prompts))
    (should (ck/eca-pair-test--said-p "no workspace root"))))

(ert-deftest ck/eca-pair-open-says-new-session-or-resume ()
  (let ((root (file-name-as-directory (make-temp-file "ck-eca-pair" t))))
    (unwind-protect
        (progn
          (ck/eca-pair-test--in-workspace root
            (ck/eca-pair-open)
            (should (ck/eca-pair-test--said-p "\\`cam-pair: new session\\'")))
          (make-directory (expand-file-name ".eca/pair" root) t)
          (write-region "20260928-101500\n" nil
                        (expand-file-name ".eca/pair/current" root)
                        nil 'silent)
          (ck/eca-pair-test--in-workspace root
            (ck/eca-pair-open)
            (should (ck/eca-pair-test--said-p
                     "\\`cam-pair: resume of session 20260928-101500\\'"))))
      (delete-directory root t))))

(provide 'eca-pair-test)
