;; -*- lexical-binding: t; -*-
;; Float every prompt that would otherwise ask at the bottom of the frame.
;; vertico-posframe (config/search.el) covers only vertico's `completing-read';
;; this covers the rest, in two layers because the entry points differ:
;;
;; - Minibuffer reads (`interactive "s"', `read-string', `M-:', `y-or-n-p',
;;   `read-passwd').  Advice on the readers misses `interactive "s"', which
;;   `call-interactively' handles in C; `minibuffer-setup-hook' catches all.
;; - Echo-area key reads (`read-char' and friends), which open no minibuffer
;;   and so are caught by advising the readers.
(require 'prelude)
(require 'core/bindings)
(require 'posframe)

(declare-vars vertico--input
              vertico-posframe-width
              vertico-posframe-min-width
              vertico-posframe-border-width)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Shared box

(defvar ck/prompt-posframe-key-reads t
  "Whether `read-char'-style echo-area prompts float in a posframe.
Set to nil to leave them at the bottom of the frame; that layer advises core
readers, so it is the first thing to turn off when a package misbehaves.")

(defvar ck/prompt-posframe-key-read-functions
  '(read-char read-char-exclusive read-key)
  "Readers whose echo-area prompt is lifted into a posframe.
`read-event' is excluded: it is also called in low-level loops with nothing
to show.")

(defvar ck/prompt-posframe-key-buffer " *ck-prompt-posframe*"
  "Buffer backing the posframe used for echo-area key prompts.")

(defun ck/prompt-posframe--width ()
  (if (boundp 'vertico-posframe-width) vertico-posframe-width 100))

(defun ck/prompt-posframe--min-width ()
  (if (boundp 'vertico-posframe-min-width) vertico-posframe-min-width 40))

(defun ck/prompt-posframe--border-width ()
  (if (boundp 'vertico-posframe-border-width) vertico-posframe-border-width 3))

(defun ck/prompt-posframe--face-color (face attribute fallback)
  "ATTRIBUTE of FACE when it exists, else that of FALLBACK."
  (face-attribute (if (facep face) face fallback) attribute nil t))

(defun ck/prompt-posframe-workable-p ()
  "Whether a prompt can be floated, false on a TTY session."
  (posframe-workable-p))

(defun ck/prompt-posframe--parent-window ()
  "The window the box anchors to: the one selected before the prompt opened.
Anchoring at the selected window would put the box at the minibuffer."
  (let ((win (minibuffer-selected-window)))
    (if (window-live-p win) win (selected-window))))

(defun ck/prompt-posframe--show (buffer &optional string extra)
  "Show BUFFER (or STRING inside it) as a floating prompt box.
EXTRA is a plist appended to the `posframe-show' arguments."
  (with-selected-window (ck/prompt-posframe--parent-window)
    (apply #'posframe-show buffer
           (append
            (when string (list :string string))
            extra
            (list
             :poshandler #'ck/posframe-poshandler-point
             :refposhandler #'ck/posframe-refposhandler
             :width (ck/prompt-posframe--width)
             :min-width (ck/prompt-posframe--min-width)
             :min-height 1
             :left-fringe 8
             :right-fringe 8
             :border-width (ck/prompt-posframe--border-width)
             :border-color (ck/prompt-posframe--face-color
                            'vertico-posframe-border :background 'default)
             :background-color (ck/prompt-posframe--face-color
                                'vertico-posframe :background 'default)
             :foreground-color (ck/prompt-posframe--face-color
                                'vertico-posframe :foreground 'default))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Covering the real minibuffer
;;
;; Two windows show the minibuffer buffer while it floats, so prompt and input
;; appear twice.  vertico-posframe's own hide (shrink the mini window, vscroll
;; it away) cannot work here: the frame owns its minibuffer, so an active
;; one-line mini window clamps back to a line, and `auto-window-vscroll' is nil
;; (init-options.el).  Cover it with a window-scoped overlay instead, and move
;; the cursor to the box: the real window is selected (`cursor-type') while the
;; box's is not (`cursor-in-non-selected-windows').

(defvar-local ck/prompt-posframe--cover-ov nil
  "Overlay blanking the real minibuffer window during a floated prompt.")

(defun ck/prompt-posframe--window (buffer)
  "The window showing BUFFER inside its posframe, or nil."
  (seq-find (lambda (w) (not (window-minibuffer-p w)))
            (get-buffer-window-list buffer nil t)))

(defun ck/prompt-posframe-cover ()
  "Blank the real minibuffer window while the box shows its buffer.
Returns the posframe's window, for callers with overlays to re-scope."
  (let* ((mbwin (active-minibuffer-window))
         (buffer (and (window-live-p mbwin) (window-buffer mbwin)))
         (pfwin (and (bufferp buffer) (ck/prompt-posframe--window buffer))))
    (when (and (window-live-p mbwin) (bufferp buffer))
      (with-current-buffer buffer
        ;; REAR-ADVANCE t: a character typed at the end of the input is
        ;; absorbed as it is inserted, so it never flashes below.
        (unless (overlayp ck/prompt-posframe--cover-ov)
          (setq ck/prompt-posframe--cover-ov
                (make-overlay (point-min) (point-max) nil nil t)))
        (move-overlay ck/prompt-posframe--cover-ov (point-min) (point-max))
        (overlay-put ck/prompt-posframe--cover-ov 'window mbwin)
        (overlay-put ck/prompt-posframe--cover-ov 'display "")
        (setq-local cursor-type nil
                    cursor-in-non-selected-windows 'box)))
    pfwin))

(defun ck/prompt-posframe-uncover ()
  "Undo `ck/prompt-posframe-cover' in the current minibuffer buffer."
  (when (overlayp ck/prompt-posframe--cover-ov)
    (delete-overlay ck/prompt-posframe--cover-ov)
    (setq ck/prompt-posframe--cover-ov nil))
  (kill-local-variable 'cursor-type)
  (kill-local-variable 'cursor-in-non-selected-windows)
  (ck/posframe-point-anchor-reset (current-buffer)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Minibuffer reads

(defun ck/prompt-posframe--float-minibuffer-p ()
  "Whether this session is ours to float, rather than vertico-posframe's.
`vertico--input' is set by `vertico--setup', which runs before this hook."
  (and (ck/prompt-posframe-workable-p)
       (not (bound-and-true-p vertico--input))))

;; These run on hooks that abort the read if they signal, so a display bug
;; costs the float, never the prompt.

(defun ck/prompt-posframe--minibuffer-refresh ()
  "Redraw the box and re-cover the real minibuffer, after every command."
  (with-demoted-errors "ck/prompt-posframe refresh: %S"
    (when (minibufferp)
      ;; `:window-point' keeps the box's caret on the input; posframe
      ;; otherwise parks it at the start of the buffer.
      (ck/prompt-posframe--show (current-buffer) nil (list :window-point (point)))
      (ck/prompt-posframe-cover))))

(defun ck/prompt-posframe--minibuffer-exit ()
  "Hide the box and restore the real minibuffer on session exit."
  (with-demoted-errors "ck/prompt-posframe exit: %S"
    (let ((buffer (current-buffer)))
      (ck/prompt-posframe-uncover)
      (posframe-hide buffer))))

(defun ck/prompt-posframe--minibuffer-setup ()
  "Float this minibuffer session unless vertico-posframe owns it."
  (with-demoted-errors "ck/prompt-posframe setup: %S"
    (when (ck/prompt-posframe--float-minibuffer-p)
      (ck/prompt-posframe--minibuffer-refresh)
      (add-hook 'post-command-hook
                #'ck/prompt-posframe--minibuffer-refresh nil 'local)
      (add-hook 'minibuffer-exit-hook
                #'ck/prompt-posframe--minibuffer-exit nil 'local))))

(add-hook 'minibuffer-setup-hook #'ck/prompt-posframe--minibuffer-setup)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Echo-area key reads

(defun ck/prompt-posframe--key-prompt (args)
  "Prompt text for a key read called with ARGS, or nil when there is none.
Either the reader was given one, or the caller `message'd it first."
  (let ((given (car-safe args)))
    (if (stringp given) given (current-message))))

(defun ck/prompt-posframe--around-key-read (fn &rest args)
  "Show a key read's prompt in a posframe instead of the echo area.
FN is always called; only its prompt display is taken over."
  (let* ((prompt (and ck/prompt-posframe-key-reads
                      (ck/prompt-posframe-workable-p)
                      (ck/prompt-posframe--key-prompt args)))
         ;; Drop the reader's own PROMPT only once the box is up, so a
         ;; failed display leaves the read exactly as it was.
         (floated (and prompt
                       (ignore-errors
                         (ck/prompt-posframe--show
                          ck/prompt-posframe-key-buffer prompt)
                         t))))
    (if (not floated)
        (apply fn args)
      (unwind-protect
          (progn
            (let ((message-log-max nil))
              (message nil))
            (apply fn (if (stringp (car-safe args)) (cons nil (cdr args)) args)))
        (ignore-errors (posframe-hide ck/prompt-posframe-key-buffer))
        (ck/posframe-point-anchor-reset
         (get-buffer ck/prompt-posframe-key-buffer))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; In-buffer completion inside a floated prompt
;;
;; corfu measures its popup in the selected window -- the covered minibuffer at
;; the bottom of the screen -- so candidates detach from the prompt.  Point it
;; at the box instead, in two steps: measure with the box's window selected,
;; then place in root coordinates, since corfu computes X and Y against the
;; selected window's frame and its EXWM support unparents the popup afterwards.
;; The two agree only for a frame at the root origin, which is why corfu is
;; correct untouched everywhere else.

(declare-functions "corfu" corfu--popup-show corfu--make-frame)

(defun ck/prompt-posframe--completion-window ()
  "The visible box standing in for the minibuffer, when one is floating."
  (and (minibufferp)
       (let ((win (ck/prompt-posframe--window (current-buffer))))
         (and (window-live-p win)
              (frame-visible-p (window-frame win))
              win))))

(defun ck/prompt-posframe--corfu-popup-show (fn pos off width lines &rest rest)
  "Measure corfu's popup against the floating box.
POS, OFF, WIDTH, LINES and REST are corfu's own arguments."
  (let ((win (ck/prompt-posframe--completion-window)))
    (if (not win)
        (apply fn pos off width lines rest)
      (with-selected-window win
        (apply fn (or (ignore-errors (posn-at-point (posn-point pos) win)) pos)
               off width lines rest)))))

(defun ck/prompt-posframe--corfu-make-frame (fn frame x y width height)
  "Re-place corfu's popup in root coordinates when it measured against a box.
FN, FRAME, X, Y, WIDTH and HEIGHT are corfu's own arguments."
  (let* ((origin (frame-position (window-frame)))
         (result (funcall fn frame x y width height)))
    (when (and (framep result)
               (null (frame-parent result))
               (not (equal origin '(0 . 0))))
      (set-frame-position result (+ (car origin) x) (+ (cdr origin) y)))
    result))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Installation
;;
;; Advice does not unwind on load, so each installer removes before adding.

(defun ck/prompt-posframe-install-key-advice ()
  "(Re)install the key-read advice."
  (dolist (fn ck/prompt-posframe-key-read-functions)
    (advice-remove fn #'ck/prompt-posframe--around-key-read)
    (advice-add fn :around #'ck/prompt-posframe--around-key-read)))

(defun ck/prompt-posframe-install-completion-advice ()
  "(Re)install the corfu placement advice."
  (when (fboundp 'corfu--popup-show)
    (advice-remove 'corfu--popup-show #'ck/prompt-posframe--corfu-popup-show)
    (advice-add 'corfu--popup-show :around
                #'ck/prompt-posframe--corfu-popup-show))
  (when (fboundp 'corfu--make-frame)
    (advice-remove 'corfu--make-frame #'ck/prompt-posframe--corfu-make-frame)
    (advice-add 'corfu--make-frame :around
                #'ck/prompt-posframe--corfu-make-frame)))

(ck/prompt-posframe-install-key-advice)
(with-eval-after-load 'corfu
  (ck/prompt-posframe-install-completion-advice))


(provide 'config/prompts)
