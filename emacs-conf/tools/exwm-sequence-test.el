;; -*- lexical-binding: t; -*-
;;; Regression checks for the X request-sequence desync heal.
;;
;; Run from the shell against the live display (a batch Emacs opens its own
;; X socket, so the WM's connection is never touched):
;;
;;   DISPLAY=:0 emacs -Q --batch --load "$lp" \
;;     -l tools/exwm-sequence-test.el -f ert-run-tests-batch-and-exit
;;
;; where "$lp" is the load-path file produced the way tools/fc-check.sh
;; builds it.
;;
;; The tests poll the socket themselves instead of calling xelb's blocking
;; reply wait: that wait passes an integer JUST-THIS-ONE to
;; `accept-process-output', which inhibits timers, so in batch its
;; `with-timeout' never fires and a lost reply hangs the process.

(require 'ert)
(require 'xcb)
(require 'xcb-xproto)
(require 'config/desktop/windows)

(defmacro ck/exwm-sequence-test--with-connection (var &rest body)
  "Bind VAR to a fresh X connection to DISPLAY for BODY, then disconnect."
  (declare (indent 1) (debug (symbolp body)))
  `(let ((,var (xcb:connect (getenv "DISPLAY"))))
     (unwind-protect (progn ,@body)
       (xcb:disconnect ,var))))

(defun ck/exwm-sequence-test--send-uncounted-request (conn)
  "Send one GetInputFocus on CONN's socket without counting it.
The server counts it, so from here on its sequence is one ahead of
CONN's tally: the state observed in the live freeze."
  (xcb:flush conn)
  (process-send-string (slot-value conn 'process)
                       (unibyte-string 43 0 1 0)))

(defun ck/exwm-sequence-test--reply-filed-p (conn)
  "Send a GetInputFocus on CONN; non-nil when its reply lands under its
own sequence number within one second."
  (let ((sequence (xcb:-+request-unchecked
                   conn (make-instance 'xcb:GetInputFocus)))
        (deadline (+ (float-time) 1.0)))
    (xcb:flush conn)
    (while (and (< (float-time) deadline)
                (symbolp (plist-get (slot-value conn 'reply-plist)
                                    sequence)))
      (accept-process-output (slot-value conn 'process) 0.1))
    (consp (plist-get (slot-value conn 'reply-plist) sequence))))

(ert-deftest ck/exwm-sequence-replies-keep-arriving-when-server-is-ahead ()
  "Replies are filed under their own request after the server counts
one extra request.  Without the heal every packet is read as a 16-bit
wrap, filed under a negative sequence, and every later wait times out."
  (ck/exwm-sequence-test--with-connection conn
    (should (ck/exwm-sequence-test--reply-filed-p conn))
    (ck/exwm-sequence-test--send-uncounted-request conn)
    (accept-process-output (slot-value conn 'process) 0.2)
    (dotimes (_ 3)
      (should (ck/exwm-sequence-test--reply-filed-p conn)))
    (should (<= 0 (slot-value conn 'last-seen-sequence)))))

(ert-deftest ck/exwm-sequence-real-wrap-is-not-a-desync ()
  "A stamp just below a 65536 boundary while the tally is just above it
is a genuine 16-bit wrap: it decodes to the earlier number and leaves the
tally alone."
  (let ((conn (make-instance 'xcb:connection)))
    (setf (slot-value conn 'request-sequence) 65540)
    (should (= 65530 (xcb:-convert-sequence conn (logand 65530 #xFFFF))))
    (should (= 65540 (slot-value conn 'request-sequence)))))
