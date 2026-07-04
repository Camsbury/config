;; -*- lexical-binding: t; -*-
(require 'config/modes/utils)

;; This module bundles the two halves of the "read text at a fixed column"
;; experience, which share one width knob:
;;
;;   * Centering (`center-buffer-mode'): when a buffer is ALONE on its frame,
;;     a left margin positions its text as if a `prettify-width'-wide column
;;     were centered on screen.  The right side is never bounded, so wide,
;;     non-column-aware content (tables, logs) flows rightward past the
;;     column.  Automatic for any opted-in buffer; hugs left when tiled.
;;
;;   * Width capping (`prettify-mode' + `ck/prettify-windows'): when the
;;     listed modes are TILED with other windows, force their window to
;;     `prettify-width' columns so they don't stretch.  Opt-in per mode:
;;     some buffers should not be squeezed, the ones hooked below should.
;;
;; Both read the same `prettify-width', so the reading column stays identical
;; whether a buffer is centered (solo) or capped (tiled).

(defvar prettify-width 80
  "Shared reading column width, in columns.
Used both as the centered-column target (`center-buffer-mode') and as
the forced window width when capping tiled windows (`ck/prettify-windows').
One knob so centering and capping never disagree.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Centering a solo buffer

(defun center-buffer--pad-width (win)
  "Left margin (in columns) to center `prettify-width' in WIN's frame.
Divides the FRAME's text width, not `window-total-width'.  The window
total jitters by a column: it folds in the fringes (which round to
columns unstably, seen as 348 vs 349 across identical frames) and is
recomputed on every `window-configuration-change' (which M-x fires),
so dividing it drifts the centered column a column sideways whenever
you touch the minibuffer.  The frame text width is stable, is what the
pre-regression version divided, and matches \"centered in the middle
of the screen\"."
  (max 0 (/ (- (frame-width (window-frame win)) prettify-width) 2)))

(defun center-buffer--pad-modeline ()
  "Left modeline padding equal to the current window's left margin.
Evaluated per window during redisplay, so it follows the margin: it
is 0 when the buffer hugs left and the pad width when it is centered."
  (let* ((margins (window-margins))
         (left (or (car margins) 0)))
    (propertize " " 'display `(space :width ,left))))

(defun center-buffer-enable-modeline-padding ()
  "Prepend the centering pad to `mode-line-format' (idempotently)."
  (let ((pad '(:eval (center-buffer--pad-modeline))))
    (unless (and (consp mode-line-format)
                 (equal (car mode-line-format) pad))
      (setq-local mode-line-format (cons pad mode-line-format)))))

(defun center-buffer-disable-modeline-padding ()
  "Drop the buffer-local `mode-line-format' override."
  (kill-local-variable 'mode-line-format))

(define-minor-mode center-buffer-mode
  "Opt this buffer into fixed-width centering when it is alone on its frame.

The flag is pure intent: it records that the buffer *wants* to be
centered.  The actual margins are managed by `center-buffer-adjust',
which centers the buffer only while it is the sole live window on its
frame and otherwise lets it hug left.  This keeps the intent stable
across splits (eca chat, `display-buffer', side windows, ...) instead
of destructively toggling the mode off and racing to turn it back on.

Never activates in EXWM buffers: managing margins and modeline padding
on an X window misbehaves, so the mode refuses to turn on there no
matter who enabled it."
  :init-value nil
  :lighter " ⊣⊢"
  (cond
   ;; Hard refusal: bail out cleanly if enabled in an EXWM buffer.
   ((and center-buffer-mode (derived-mode-p 'exwm-mode))
    (setq center-buffer-mode nil))
   (center-buffer-mode
    (center-buffer-enable-modeline-padding)
    (center-buffer-adjust))
   (t
    ;; Reset margins on every window actually showing this buffer, not
    ;; whatever window happens to be selected right now.
    (dolist (w (get-buffer-window-list (current-buffer) nil t))
      (set-window-margins w 0 0))
    (center-buffer-disable-modeline-padding))))

(defun center-buffer-adjust (&rest _)
  "Center or left-align every centered buffer based on horizontal space.

Runs from the *global* `window-configuration-change-hook' /
`window-state-change-functions', so it reacts to any layout change
regardless of cause.  For every live (non-minibuffer) window on every
frame: if its buffer opted in (`center-buffer-mode', non-EXWM) it is
centered only while its window spans the full frame width, otherwise
its margins are cleared so it hugs left.

The test is `window-full-width-p', NOT \"sole window on the frame\":
only a left/right neighbour (an eca chat, a vertical split) steals the
horizontal room that makes centering wrong.  Bottom popups that take no
horizontal space -- hydra's `lv' hint window, which-key's bottom
side-window, the minibuffer, completion buffers -- leave the buffer
full-width, so they must never pull a centered buffer over.  Windows
whose buffer never opted in are left untouched, so we never clobber
other packages' margins."
  (dolist (frame (frame-list))
    (dolist (w (window-list frame 'no-mini))
      (with-current-buffer (window-buffer w)
        (when (and center-buffer-mode (not (derived-mode-p 'exwm-mode)))
          (set-window-margins
           w (if (window-full-width-p w) (center-buffer--pad-width w) 0) 0))))))

;; React to layout changes globally.  Buffer-local values of these hooks
;; fire only for windows already showing the buffer whose configuration
;; changed, which misses a sibling window (eca chat) appearing beside a
;; centered buffer.  The global value always runs.  `add-hook' dedupes by
;; symbol, so re-loading this file does not accumulate registrations.
(add-hook 'window-configuration-change-hook #'center-buffer-adjust)
(when (boundp 'window-state-change-functions)
  (add-hook 'window-state-change-functions #'center-buffer-adjust))

(defun center-buffer--center-when-single ()
  "Enable `center-buffer-mode' in the current buffer when it is alone.
No-op if the buffer is already opted in or is not the sole window."
  (interactive)
  (let* ((win (get-buffer-window (current-buffer) 'visible))
         (n   (length (window-list (and win (window-frame win)) 'no-mini))))
    (unless (or center-buffer-mode (> n 1))
      (center-buffer-mode 1))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Aligning bottom-anchored UI (minibuffer, hydra hint) with the column

;; The minibuffer and hydra's `lv' hint sit at the bottom of the frame,
;; spanning the whole width, so their text hugs the far left even when the
;; document they relate to is centered.  Give each the SAME left offset as
;; the centered source buffer so entering text about that document stays in
;; the same vertical column instead of jumping to the edge.  The `lv' hint
;; takes a window margin, but the minibuffer must use a `line-prefix'
;; instead (see `center-buffer--adjust-minibuffer' for why a margin fails
;; there).

(defun center-buffer--source-pad (win)
  "Left offset (columns) for a frame-anchored UI element anchored at WIN.
Reuses the centering pad (`center-buffer--pad-width') when WIN shows a
centered, full-width, non-EXWM buffer, and 0 otherwise.  The 0 case is
what makes the offset vanish in a tiled layout: there is no full-width
centered source window to align under, so the bottom UI hugs left like
the buffers do."
  (if (and (window-live-p win)
           (window-full-width-p win)
           (with-current-buffer (window-buffer win)
             (and center-buffer-mode (not (derived-mode-p 'exwm-mode)))))
      (center-buffer--pad-width win)
    0))

(defun center-buffer--adjust-minibuffer ()
  "Indent the active minibuffer to align under its centered source buffer.
`minibuffer-selected-window' is the window the minibuffer was entered
from -- the document being acted on -- so its centering pad is the
offset we want.

Uses a buffer-local `line-prefix'/`wrap-prefix' rather than a window
margin.  A window margin on the LIVE minibuffer window does not repaint
until a command-loop redisplay, so a margin only appears on the first
keystroke (it \"snaps over\").  A line prefix is part of the buffer's
own layout, computed on the initial paint, so the offset shows the
instant the minibuffer opens.  The prefix is set on the minibuffer
buffer (current during `minibuffer-setup-hook'); the echo area uses a
different buffer, so messages between reads stay flush left.  Cleared
to nil when there is no centered source (tiled layout), which also
resets any prefix left over from a prior read of this reused buffer."
  (let* ((pad  (center-buffer--source-pad (minibuffer-selected-window)))
         (spec (and (> pad 0) (propertize " " 'display `(space :width ,pad)))))
    (setq-local line-prefix spec
                wrap-prefix spec)))

(add-hook 'minibuffer-setup-hook #'center-buffer--adjust-minibuffer)

(defun center-buffer--adjust-lv (&rest _)
  "Offset hydra's `lv' hint window to align under the centered source.
A hydra never selects the hint window, so `selected-window' is still
the document the hydra is acting on.  Runs as `:after' advice on
`lv-message', which has already created the hint window."
  (when (fboundp 'lv-window)
    (let ((w (lv-window)))
      (when (window-live-p w)
        (set-window-margins
         w (center-buffer--source-pad (selected-window)) 0)))))

;; `advice-add' dedupes by symbol, so re-loading this file does not stack
;; the advice.  `with-eval-after-load' runs now if `lv' is already loaded
;; (it is once any hydra hint has rendered) and defers otherwise.
(with-eval-after-load 'lv
  (advice-add 'lv-message :after #'center-buffer--adjust-lv))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Capping tiled windows to `prettify-width'

(define-minor-mode prettify-mode
  "Cap this buffer's window to `prettify-width' when it is tiled.
Opt-in: hooked below onto the modes that should be squeezed to the
reading column when sharing a frame."
  :lighter " prettify"
  :global nil)

(defun ck/prettify-windows ()
  "Center the current buffer when solo, and cap tiled prettify windows.
`ck/set-window-width' is a no-op unless the window is tiled with a
right neighbour, so this only squeezes when there is space to reclaim.

Order matters: `center-buffer-adjust' is called *before* capping so
margins already reflect the current layout (0 when tiled).  The
reactive margin hook is deferred to redisplay, but this runs
synchronously right after a split / eca display, and a stale centering
margin would corrupt `ck/set-window-width''s body-width math."
  (interactive)
  (center-buffer--center-when-single)
  (center-buffer-adjust)
  (with-selected-window (frame-first-window)
    (dolist (w (window-list))
      (with-selected-window w
        (when (ck/minor-mode-active-p 'prettify-mode)
          (ck/set-window-width w prettify-width))))))

;; non-prog modes that should be squeezed to `prettify-width' when tiled
;; NOTE: `general-add-hook' is a bare `add-hook' wrapper with no normalization,
;; so every entry must be an actual hook variable (`-hook' suffix).  A plain
;; mode symbol like `eca-chat-mode' would attach to a symbol nothing runs.
(general-add-hook
 '(eca-chat-mode-hook
   nxml-mode-hook
   haskell-cabal-mode-hook)
 #'prettify-mode)

;; when to run the frame pass
(general-add-hook
 '(find-file-hook after-delete-window-hook after-split-window-hook)
 #'ck/prettify-windows)

(provide 'config/modes/prettify-mode)
