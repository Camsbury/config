;; -*- lexical-binding: t; -*-
;;; Regression checks for bounded ECA transcript windows.

(require 'ert)
(require 'cl-lib)
(require 'config/services/eca/windowing)

(defmacro ck/eca-windowing-test--with-chat (&rest body)
  "Run BODY in a minimal ECA chat buffer."
  (declare (indent 0) (debug t))
  `(with-temp-buffer
     (setq major-mode 'eca-chat-mode)
     (setq-local eca-chat--id "chat-1"
                 eca-chat--chat-loading nil
                 eca-chat--history-loading nil
                 eca-chat--pending-question nil)
     ,@body))

(ert-deftest ck/eca-windowing-enqueues-only-idle-oversize-chats ()
  (let ((ck/eca-chat-render-max-bytes 10)
        (ck/eca-chat--window-queue nil)
        (ck/eca-chat--window-active nil))
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      (ck/eca-chat--maybe-window)
      (should (equal ck/eca-chat--window-queue (list (current-buffer))))
      (ck/eca-chat--maybe-window)
      (should (= 1 (length ck/eca-chat--window-queue))))
    (setq ck/eca-chat--window-queue nil)
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      (setq-local eca-chat--chat-loading t)
      (ck/eca-chat--maybe-window)
      (should-not ck/eca-chat--window-queue))))

(ert-deftest ck/eca-windowing-reopens-with-a-bounded-latest-page ()
  (let ((ck/eca-chat-render-max-bytes 10)
        (ck/eca-chat-window-message-limit 7)
        (ck/eca-chat--window-queue nil)
        (ck/eca-chat--window-active nil)
        captured)
    (ck/eca-windowing-test--with-chat
      (insert "01234567890")
      (cl-letf (((symbol-function 'eca-session) (lambda () 'session))
                ((symbol-function 'eca-chat--prompt-field-start-point)
                 (lambda () (point-max)))
                ((symbol-function 'eca-api-request-async)
                 (lambda (_session &rest args)
                   (setq captured args))))
        (ck/eca-chat--maybe-window)
        (ck/eca-chat--dispatch-window-queue)
        (should (eq ck/eca-chat--window-active (current-buffer)))
        (should (equal (plist-get captured :method) "chat/open"))
        (should (equal (plist-get captured :params)
                       '(:chatId "chat-1" :limit 7)))))))

(provide 'eca-windowing-test)
