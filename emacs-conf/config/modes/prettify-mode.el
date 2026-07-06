;; -*- lexical-binding: t; -*-
(require 'config/modes/utils)

;; This module bundles the pieces of the "read text at a fixed column"
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
;;   * Margin capping (`margin-cap-mode'): leave the window alone and bound
;;     the TEXT AREA instead, absorbing surplus columns into the right
;;     margin.  For buffers that soft-wrap at the window edge (eca chat's
;;     `word-wrap') and sit where window capping never fires (the rightmost
;;     window has no right neighbour to donate space to).
;;
;; All read the same `prettify-width', so the reading column stays identical
;; whether a buffer is centered (solo), capped (tiled), or margin-capped.

(defvar prettify-width 86
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

(defun center-buffer--pad-line ()
  "Left padding equal to the current window's left margin.
Evaluated per window during redisplay of a mode/header/tab line, so it
tracks the margin: 0 when the buffer hugs left, the pad width when it is
centered.  Because it reads the LIVE margin, the padding element is
self-collapsing -- harmless to leave in a tiled buffer's line, where it
renders nothing."
  (let* ((margins (window-margins))
         (left (or (car margins) 0)))
    (propertize " " 'display `(space :width ,left))))

(defconst center-buffer--padded-line-vars
  '(mode-line-format header-line-format tab-line-format)
  "Full-width decoration lines whose left content should follow the margin.
Each spans the whole window at column 0, so a centered buffer's mode
line, header line (e.g. eca chat's) and tab line would otherwise hug the
far left while the body sits in the centered column.")

(defun center-buffer--pad-element-p (el)
  "Non-nil when EL is any center-buffer padding construct.
Matches `(:eval (SYM ...))' where SYM's name starts with
\"center-buffer--pad\", so it recognizes the current pad element AND any
older or renamed variant (e.g. a stale `center-buffer--pad-modeline'
baked into a buffer-local line by a prior load).  Matching on the name
prefix rather than an exact form is what keeps a rename from silently
stacking a second pad on the next reload."
  (and (consp el)
       (eq (car el) :eval)
       (consp (cadr el))
       (symbolp (car (cadr el)))
       (string-prefix-p "center-buffer--pad"
                        (symbol-name (car (cadr el))))))

(defun center-buffer--line-list-p (fmt)
  "Non-nil when FMT is a list OF constructs, not a single construct.
A mode-line value is a list of constructs only when its car is itself a
string or a sub-construct (a cons); a car that is a keyword (`:eval',
`:propertize'), a plain symbol (a `(SYMBOL THEN ELSE)' conditional) or an
integer marks FMT as one construct that must be left whole."
  (and (consp fmt)
       (or (stringp (car fmt)) (consp (car fmt)))))

(defun center-buffer--strip-pads (fmt)
  "Return a copy of mode-line value FMT with all our pad constructs removed.
Recurses only through genuine lists of constructs
(`center-buffer--line-list-p'), never into an `(:eval FORM)' body, so it
cleans a pad wherever a prior load left it -- including one nested inside
an older wrapper -- without walking into unrelated data (e.g. eca's
session struct carried in its own `:eval')."
  (cond
   ((center-buffer--pad-element-p fmt) nil)
   ((center-buffer--line-list-p fmt)
    (let (acc)
      (dolist (el fmt)
        (cond
         ((center-buffer--pad-element-p el))
         ((center-buffer--line-list-p el)
          (let ((s (center-buffer--strip-pads el)))
            (when s (push s acc))))
         (t (push el acc))))
      (nreverse acc)))
   (t fmt)))

(defun center-buffer-enable-line-padding ()
  "Prepend the centering pad to each present mode/header/tab line.
Self-healing and idempotent: strips ANY prior center-buffer pad
(`center-buffer--strip-pads') before prepending a fresh one, so re-running
never stacks pads and a stale variant left by an earlier load is cleared
rather than doubled (the double-pad that shifted a reloaded modeline
right).  Skips a nil line so we never conjure a header or tab line where
the buffer has none.  Prepends flat when the stripped line is a list of
constructs, and wraps in a two-element list when it is a single construct
(e.g. `tab-line-format's lone `(:eval ...)'), so the result is always a
valid list of constructs."
  (let ((pad '(:eval (center-buffer--pad-line))))
    (dolist (var center-buffer--padded-line-vars)
      (let ((fmt (symbol-value var)))
        (when fmt
          (let ((stripped (center-buffer--strip-pads fmt)))
            (set (make-local-variable var)
                 (cond
                  ((null stripped) (list pad))
                  ((center-buffer--line-list-p stripped) (cons pad stripped))
                  (t (list pad stripped))))))))))

(defun center-buffer-disable-line-padding ()
  "Remove every center-buffer pad from each mode/header/tab line.
Strips all our pad variants (`center-buffer--strip-pads') while preserving
the rest of a line another package (eca chat, tab-line-mode) owns."
  (dolist (var center-buffer--padded-line-vars)
    (when (local-variable-p var)
      (set var (center-buffer--strip-pads (symbol-value var))))))

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
    ;; `center-buffer-adjust' asserts the line padding for this buffer.
    (center-buffer-adjust))
   (t
    ;; Reset margins on every window actually showing this buffer, not
    ;; whatever window happens to be selected right now.
    (dolist (w (get-buffer-window-list (current-buffer) nil t))
      (set-window-margins w 0 0))
    (center-buffer-disable-line-padding))))

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
          ;; In-tandem chrome (mode/header/tab line) rides the margin.
          (center-buffer-enable-line-padding)
          (set-window-margins
           w (if (window-full-width-p w) (center-buffer--pad-width w) 0) 0)))))
  ;; The echo area is frame-anchored chrome, not a window in the list above.
  (center-buffer--adjust-echo))

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
No-op if the buffer is already opted in, is not the sole window, or is
margin-capped (`margin-cap-mode' bounds BOTH sides and does its own
full-width centering, so plain centering would only undo the right
bound)."
  (interactive)
  (let* ((win (get-buffer-window (current-buffer) 'visible))
         (n   (length (window-list (and win (window-frame win)) 'no-mini))))
    (unless (or center-buffer-mode
                (bound-and-true-p margin-cap-mode)
                (> n 1))
      (center-buffer-mode 1))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Aligning frame-anchored chrome (minibuffer, hydra hint, echo area)

;; Same idea as the in-tandem decoration lines above, but for chrome that
;; is anchored to the whole frame rather than living inside the centered
;; window: the minibuffer, hydra's `lv' hint, and the echo area all sit at
;; the bottom spanning the full width, so their text hugs the far left even
;; when the document they relate to is centered.  Give each the SAME left
;; offset as the centered source so entering (or reading) text about that
;; document stays in the same vertical column instead of jumping to the
;; edge.  The mechanism differs by target: the `lv' hint takes a window
;; margin, but the minibuffer and echo area must use a `line-prefix'
;; instead (see `center-buffer--adjust-minibuffer' for why a margin fails
;; on a live minibuffer window).

(defun center-buffer--source-pad (win)
  "Left offset (columns) for a frame-anchored UI element anchored at WIN.
Reuses the centering pad (`center-buffer--pad-width') when WIN shows a
centered, full-width, non-EXWM buffer, and 0 otherwise.  The 0 case is
what makes the offset vanish in a tiled layout: there is no full-width
centered source window to align under, so the bottom UI hugs left like
the buffers do.  A margin-capped buffer (`margin-cap-mode') counts as a
source too: full-width it centers the same column via the same pad, so
the bottom UI should ride it identically."
  (if (and (window-live-p win)
           (window-full-width-p win)
           (with-current-buffer (window-buffer win)
             (and (or center-buffer-mode (bound-and-true-p margin-cap-mode))
                  (not (derived-mode-p 'exwm-mode)))))
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
buffer (current during `minibuffer-setup-hook'); the echo area uses
different buffers, handled by `center-buffer--adjust-echo'.  Cleared to
nil when there is no centered source (tiled layout), which also resets
any prefix left over from a prior read of this reused buffer."
  ;; vertico-posframe renders the minibuffer in a floating child frame that
  ;; positions itself, so this source-alignment indent is not merely useless
  ;; there but actively shifts the posframe's contents sideways.  Force pad 0
  ;; while posframe-mode is active (still clears any stale prefix); the indent
  ;; returns on its own if posframe-mode is later turned off.
  (let* ((pad  (if (bound-and-true-p vertico-posframe-mode)
                   0
                 (center-buffer--source-pad (minibuffer-selected-window))))
         (spec (and (> pad 0) (propertize " " 'display `(space :width ,pad)))))
    (setq-local line-prefix spec
                wrap-prefix spec)
    ;; Marginalia anchors its annotation column with `:align-to (+ left N)',
    ;; where `left' is the WINDOW TEXT AREA edge, not where this line's text
    ;; starts.  The line prefix above consumes `pad' columns inside the text
    ;; area, so marginalia's column would land to the LEFT of the shifted
    ;; candidates and the stretch glyph collapses -- annotations glue to
    ;; their candidates, alignment gone.  Shift the anchor by the same pad
    ;; (buffer-locally: `marginalia--align' runs with the minibuffer
    ;; current), preserving any user-set default offset; nil pad case still
    ;; resets a stale local from a prior read of this reused buffer."
    (when (boundp 'marginalia-align-offset)
      (setq-local marginalia-align-offset
                  (+ pad (default-value 'marginalia-align-offset))))))

(add-hook 'minibuffer-setup-hook #'center-buffer--adjust-minibuffer)

(defun center-buffer--adjust-echo (&rest _)
  "Indent echo-area messages to align under the centered selected window.
A `message' renders in the echo-area buffers, not in the active-read
buffer, so the `minibuffer-setup-hook' prefix never touches it.  Give
those buffers the same `line-prefix' as the currently selected centered
window (nil -> flush left when the selected window is not a full-width
centered buffer, e.g. a tiled layout).  Runs from the same layout hooks
as `center-buffer-adjust', so the prefix is already correct by the time
a message appears while the layout is stable."
  (let* ((pad  (center-buffer--source-pad (frame-selected-window)))
         (spec (and (> pad 0) (propertize " " 'display `(space :width ,pad)))))
    (dolist (name '(" *Minibuf-0*" " *Echo Area 0*" " *Echo Area 1*"))
      (when (get-buffer name)
        (with-current-buffer name
          (setq-local line-prefix spec
                      wrap-prefix spec))))))

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
          ;; A margin cap hides the surplus from the capper:
          ;; `ck/set-window-width' measures `window-width' (body only,
          ;; margins excluded), so a margin-capped window already reads
          ;; `prettify-width' and the snap would no-op.  Drop the margins
          ;; first; `margin-cap-adjust' below re-absorbs whatever the snap
          ;; could not reclaim.
          (when (bound-and-true-p margin-cap-mode)
            (set-window-margins w 0 0))
          (ck/set-window-width w prettify-width)))))
  (margin-cap-adjust))

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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Capping the text area with margins (eca chat)

;; Window capping above squeezes a window down to `prettify-width', but it
;; only works when there is a right neighbour to donate the surplus to.  The
;; eca chat is the rightmost (often only-sibling) window, so it never gets
;; capped and its `word-wrap' lines run to the window edge.  Margin capping
;; takes the opposite approach: keep the window at whatever width the layout
;; wants and shrink the TEXT AREA to `prettify-width' by absorbing the
;; surplus into the right margin.  Everything that wraps at the window edge
;; now wraps at the reading column, while width-aware machinery keeps
;; working: eca's `---' separator is a face-extended horizontal rule that
;; follows the text area, and `eca-table' compares against `window-width'
;; (which excludes margins), so a wide table's "scrollable" mode pans inside
;; the capped column.  Text hugs left, matching tiled buffers, which also
;; means no mode/header-line padding is needed (that chrome only misaligns
;; when a LEFT margin pushes the body over).

(define-minor-mode margin-cap-mode
  "Cap this buffer's text area to `prettify-width' using window margins.

Like `center-buffer-mode' the flag is pure intent: the actual margins
are managed by `margin-cap-adjust' from the global window hooks, so the
cap tracks resizes, re-displays, and windows the buffer appears in
later.  Supersedes `center-buffer-mode' rather than coexisting with it:
capping bounds BOTH sides (and centers itself when full-width), so
enabling this mode turns plain centering off, and
`center-buffer--center-when-single' skips capped buffers so a solo
layout cannot turn it back on and undo the right bound.

Never activates in EXWM buffers, same as centering: margin management
on an X window misbehaves."
  :init-value nil
  :lighter " ⊢⊣"
  (cond
   ((and margin-cap-mode (derived-mode-p 'exwm-mode))
    (setq margin-cap-mode nil))
   (margin-cap-mode
    ;; Take over from centering cleanly: turning it off resets margins
    ;; and strips its line pads; the adjust below re-asserts both.
    (when center-buffer-mode (center-buffer-mode -1))
    (margin-cap-adjust))
   (t
    ;; Reset margins on every window actually showing this buffer.
    (dolist (w (get-buffer-window-list (current-buffer) nil t))
      (set-window-margins w 0 0))
    (center-buffer-disable-line-padding))))

(defun margin-cap-adjust (&rest _)
  "Re-assert the margin cap on every window showing a capped buffer.

Runs from the global `window-configuration-change-hook' /
`window-state-change-functions' (same registration pattern as
`center-buffer-adjust'), so a chat window created by `display-buffer',
resized by a split, or re-shown from the buffer list all get the cap
without per-window bookkeeping.  Idempotent: the available width is
computed as body + current margins, so re-running on an already-capped
window sets the same margins again rather than compounding.

Placement mirrors centering: a full-width window centers the column
(reusing `center-buffer--pad-width' so the reading column lands exactly
where a centered buffer's would), a tiled window hugs left.  Either
way the right margin absorbs the rest, which is the whole point.  The
mode/header/tab-line pads ride the live margin
(`center-buffer-enable-line-padding'), self-collapsing in the hug-left
case."
  (dolist (frame (frame-list))
    (dolist (w (window-list frame 'no-mini))
      (with-current-buffer (window-buffer w)
        (when (and margin-cap-mode (not (derived-mode-p 'exwm-mode)))
          (let* ((margins (window-margins w))
                 (avail (+ (window-body-width w)
                           (or (car margins) 0)
                           (or (cdr margins) 0)))
                 (left (if (window-full-width-p w)
                           (min (center-buffer--pad-width w)
                                (max 0 (- avail prettify-width)))
                         0))
                 (right (max 0 (- avail prettify-width left))))
            (center-buffer-enable-line-padding)
            (set-window-margins w left right)))))))

;; Same global hooks as centering; `add-hook' dedupes by symbol, so
;; re-loading this file does not accumulate registrations.
(add-hook 'window-configuration-change-hook #'margin-cap-adjust)
(when (boundp 'window-state-change-functions)
  (add-hook 'window-state-change-functions #'margin-cap-adjust))

(defun margin-cap--reset-margins-for-split (&optional window &rest _)
  "Zero WINDOW's margins so `split-window' has room to split it.
`split-window' treats margins as fixed width, so a window whose margins
absorb most of the frame (a capped OR centered buffer) is \"too small
for splitting\" even when the underlying window is huge.  Dropping the
margins just before the split fixes that; the reactive adjust passes
(`margin-cap-adjust', `center-buffer-adjust') re-assert the correct
margins for the new layout on the very next configuration change."
  (let ((w (if (windowp window) window (selected-window))))
    (when (and (window-live-p w)
               (with-current-buffer (window-buffer w)
                 (or margin-cap-mode center-buffer-mode)))
      (set-window-margins w 0 0))))

;; `advice-add' dedupes by symbol, so re-loading does not stack advice.
(advice-add 'split-window :before #'margin-cap--reset-margins-for-split)

;; The eca chat opts into BOTH: window capping (`prettify-mode', hooked
;; above) snaps a tiled chat window down to the reading column so the
;; sibling gets the surplus, exactly as before; margin capping only covers
;; what the snap cannot reach (a full-width/solo chat window, where there is
;; no sibling to donate space to), bounding the text area instead.  On a
;; snapped window the margin cap self-collapses to zero.
(add-hook 'eca-chat-mode-hook #'margin-cap-mode)

(provide 'config/modes/prettify-mode)
