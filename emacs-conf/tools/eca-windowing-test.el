;; -*- lexical-binding: t; -*-
;;; Regression checks for bounded ECA transcript windows.

(require 'ert)
(require 'cl-lib)
(require 'config/services/eca/windowing)
;; Load the in-memory fake adapter AFTER windowing pulled in the real one, so
;; its `ck/eca-upstream-' definitions win and the tests drive the satellite
;; without a live eca-emacs session.
(load (expand-file-name
       "eca-upstream-fake"
       (file-name-directory (or load-file-name buffer-file-name))))

(defmacro ck/eca-windowing-test--with-chat (&rest body)
  "Run BODY in a minimal ECA chat buffer."
  (declare (indent 0) (debug t))
  `(with-temp-buffer
     (setq major-mode 'eca-chat-mode)
     (ck/eca-upstream-fake-setup-chat :id "chat-1")
     ,@body))

(ert-deftest ck/eca-windowing-enqueues-only-idle-oversize-chats ()
  (let ((ck/eca-chat-render-max-bytes 10)
        (ck/eca-chat--window-queue nil)
        (ck/eca-chat--window-active nil))
    (ck/eca-upstream-fake-reset)
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      (ck/eca-chat--maybe-window)
      (should (equal ck/eca-chat--window-queue (list (current-buffer))))
      (ck/eca-chat--maybe-window)
      (should (= 1 (length ck/eca-chat--window-queue))))
    (setq ck/eca-chat--window-queue nil)
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      (ck/eca-upstream-fake-setup-chat :id "chat-1" :chat-loading t)
      (ck/eca-chat--maybe-window)
      (should-not ck/eca-chat--window-queue))))

(ert-deftest ck/eca-windowing-reopens-with-a-bounded-latest-page ()
  (let ((ck/eca-chat-render-max-bytes 10)
        (ck/eca-chat-window-message-limit 7)
        (ck/eca-chat--window-queue nil)
        (ck/eca-chat--window-active nil))
    (ck/eca-upstream-fake-reset)
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      ;; An empty prompt: the field starts at point-max, so the re-window
      ;; carries no pending prompt text (mirrors the old point-max fake).
      (ck/eca-upstream-fake-setup-chat :id "chat-1"
                                       :prompt-field-start-point (point-max))
      (ck/eca-chat--maybe-window)
      (ck/eca-chat--dispatch-window-queue)
      (should (eq ck/eca-chat--window-active (current-buffer)))
      (let ((captured (ck/eca-upstream-fake-last-request)))
        (should (equal (plist-get captured :method) "chat/open"))
        (should (equal (plist-get captured :params)
                       '(:chatId "chat-1" :limit 7)))))))

(provide 'eca-windowing-test)
