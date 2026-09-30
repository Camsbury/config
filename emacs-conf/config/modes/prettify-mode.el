;; -*- lexical-binding: t; -*-
(require 'lib/utils)
(require 'core/definers)   ; general-add-hook

;; Holds text at one reading column, `prettify-width'.  Centering
;; (`center-buffer-mode') adds a left margin so a solo buffer's text sits in
;; a centered column.  Window capping (`prettify-mode') shrinks a tiled
;; window to that column.  Margin capping (`margin-cap-mode') keeps the
;; window width and shrinks the text area instead.  All three read the same
;; width, and each section below states when its mechanism applies.

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
total jitters by a column: it folds in fringes that round to columns
unstably, and it is recomputed on every `window-configuration-change'
(which M-x fires), so dividing it drifts the centered column sideways
whenever you touch the minibuffer."
  (max 0 (/ (- (frame-width (window-frame win)) prettify-width) 2)))

(defun center-buffer--pad-line ()
  "Left padding equal to the current window's left margin.
Evaluated per window during redisplay of a mode/header/tab line, so it
tracks the margin: 0 when the buffer hugs left, the pad width when it is
centered.  Reading the LIVE margin makes the element self-collapsing, so
it is harmless to leave in a tiled buffer's line."
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
\"center-buffer--pad\", so a renamed or stale pad baked into a
buffer-local line by an earlier load is still recognized.  Matching the
name prefix rather than an exact form keeps a rename from stacking a
second pad on the next reload."
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
cleans a pad wherever a prior load left it without walking into unrelated
data such as eca's session struct carried in its own `:eval'."
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
Idempotent: strips ANY prior center-buffer pad
(`center-buffer--strip-pads') before prepending a fresh one, so
re-running never stacks pads.  Skips a nil line so we never conjure a
header or tab line where the buffer has none.  Prepends flat when the
stripped line is a list of constructs, and wraps in a two-element list
when it is a single construct (`tab-line-format's lone `(:eval ...)'),
so the result is always a valid list of constructs."
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

The flag is pure intent.  `center-buffer-adjust' owns the margins and
centers the buffer only while it is the sole live window on its frame.
The intent therefore survives splits (eca chat, `display-buffer', side
windows) with no need to toggle the mode off and on again.

Never activates in EXWM buffers: managing margins and modeline padding
on an X window misbehaves, so the mode refuses to turn on there no
matter who enabled it."
  :init-value nil
  :lighter " ⊣⊢"
  (cond
   ((and center-buffer-mode (derived-mode-p 'exwm-mode))
    (setq center-buffer-mode nil))
   (center-buffer-mode
    ;; `center-buffer-adjust' asserts the line padding for this buffer.
    (center-buffer-adjust))
   (t
    ;; Every window showing this buffer, not just the selected one.
    (dolist (w (get-buffer-window-list (current-buffer) nil t))
      (set-window-margins w 0 0))
    (center-buffer-disable-line-padding))))

(defun center-buffer-adjust (&rest _)
  "Center or left-align every centered buffer based on horizontal space.

Runs from the *global* `window-configuration-change-hook' /
`window-state-change-functions', so it reacts to any layout change.  For
every live (non-minibuffer) window on every frame: a buffer that opted in
(`center-buffer-mode', non-EXWM) is centered only while its window spans
the full frame width, otherwise its margins are cleared so it hugs left.
Windows whose buffer never opted in are left untouched, so we never
clobber other packages' margins.

The test is `window-full-width-p', NOT \"sole window on the frame\":
only a left/right neighbour steals the horizontal room that makes
centering wrong.  Bottom popups take no horizontal space (hydra's `lv'
hint, which-key, the minibuffer, completion buffers), leave the buffer
full-width, and must never pull it over."
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

;; Use the global hook value: a buffer-local value fires only for windows
;; already showing the changed buffer, which misses a sibling window (eca
;; chat) appearing beside a centered one.  `add-hook' dedupes by symbol, so
;; re-loading this file does not accumulate registrations.
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

;; Chrome anchored to the frame rather than to the centered window (the
;; minibuffer, hydra's `lv' hint, the echo area) spans the full width, so
;; its text hugs the far left while the document it relates to is centered.
;; Give each the same left offset as the centered source.  The mechanism
;; differs by target: the `lv' hint takes a window margin, but the
;; minibuffer and echo area must use a `line-prefix' instead (see
;; `center-buffer--adjust-minibuffer' for why a margin fails there).

(defun center-buffer--source-pad (win)
  "Left offset (columns) for a frame-anchored UI element anchored at WIN.
Reuses the centering pad (`center-buffer--pad-width') when WIN shows a
centered or margin-capped, full-width, non-EXWM buffer, and 0 otherwise.
The 0 case is what makes the offset vanish in a tiled layout: there is no
full-width centered source window to align under, so the bottom UI hugs
left like the buffers do."
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
from, so its centering pad is the offset we want.

Uses a buffer-local `line-prefix'/`wrap-prefix' rather than a window
margin.  A margin on the LIVE minibuffer window does not repaint until a
command-loop redisplay, so it would only appear on the first keystroke.
A line prefix is part of the buffer's own layout, so the offset shows the
instant the minibuffer opens.  The echo area uses different buffers,
handled by `center-buffer--adjust-echo'.  A nil prefix resets whatever a
prior read of this reused buffer left behind."
  ;; vertico-posframe renders the minibuffer in a floating child frame that
  ;; positions itself, so this indent would shift the posframe's contents
  ;; sideways.  Force pad 0 while posframe-mode is active, which still clears
  ;; any stale prefix.
  (let* ((pad  (if (bound-and-true-p vertico-posframe-mode)
                   0
                 (center-buffer--source-pad (minibuffer-selected-window))))
         (spec (and (> pad 0) (propertize " " 'display `(space :width ,pad)))))
    (setq-local line-prefix spec
                wrap-prefix spec)
    ;; Marginalia anchors its annotation column with `:align-to (+ left N)',
    ;; where `left' is the WINDOW TEXT AREA edge, not where this line's text
    ;; starts.  The line prefix above consumes `pad' columns inside the text
    ;; area, so without the same shift marginalia's column lands LEFT of the
    ;; candidates and its stretch glyph collapses.  Shift buffer-locally on
    ;; top of the user's default; pad 0 resets a stale local.
    (when (boundp 'marginalia-align-offset)
      (setq-local marginalia-align-offset
                  (+ pad (default-value 'marginalia-align-offset))))))

(add-hook 'minibuffer-setup-hook #'center-buffer--adjust-minibuffer)

(defun center-buffer--adjust-echo (&rest _)
  "Indent echo-area messages to align under the centered selected window.
A `message' renders in the echo-area buffers, not in the active-read
buffer, so the `minibuffer-setup-hook' prefix never touches it.  Give
those buffers the same `line-prefix' as the currently selected centered
window, and nil (flush left) when that window is not a full-width
centered buffer.  Runs from the same layout hooks as
`center-buffer-adjust', so the prefix is correct before a message
appears."
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
;; and defers otherwise.
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
margins already reflect the current layout (0 when tiled).  The reactive
margin hook waits for redisplay, but this runs right after a split, and a
stale centering margin would corrupt `ck/set-window-width''s body-width
math."
  (interactive)
  (center-buffer--center-when-single)
  (center-buffer-adjust)
  (with-selected-window (frame-first-window)
    (dolist (w (window-list))
      (with-selected-window w
        (when (ck/minor-mode-active-p 'prettify-mode)
          ;; A margin cap hides the surplus from the capper:
          ;; `ck/set-window-width' measures `window-width', which excludes
          ;; margins, so a capped window already reads `prettify-width' and
          ;; the snap would no-op.  Drop the margins first; `margin-cap-adjust'
          ;; below re-absorbs what the snap could not reclaim.
          (when (bound-and-true-p margin-cap-mode)
            (set-window-margins w 0 0))
          (ck/set-window-width w prettify-width)))))
  (margin-cap-adjust))

;; non-prog modes that should be squeezed to `prettify-width' when tiled.
;; `general-add-hook' is a bare `add-hook' wrapper with no normalization, so
;; every entry must be an actual hook variable (`-hook' suffix).  A plain
;; mode symbol like `eca-chat-mode' would attach to a symbol nothing runs.
(general-add-hook
 '(eca-chat-mode-hook
   nxml-mode-hook
   haskell-cabal-mode-hook)
 #'prettify-mode)

(defun ck/prettify-eca-chat-after-display ()
  "Resize ECA chat windows after their buffer and display both exist.
`eca-chat-mode-hook' enables `prettify-mode' before `display-buffer' has
finished creating the chat window.  Deferring one event-loop turn lets the
window exist and ensures `ck/prettify-windows' sees the enabled mode."
  (run-at-time 0 nil #'ck/prettify-windows))

;; Append so `prettify-mode' is enabled before the deferred frame pass.
(add-hook 'eca-chat-mode-hook #'ck/prettify-eca-chat-after-display t)

;; when to run the frame pass
(general-add-hook
 '(find-file-hook after-delete-window-hook after-split-window-hook)
 #'ck/prettify-windows)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Capping the text area with margins (eca chat)

;; Window capping above needs a right neighbour to donate the surplus to.
;; The eca chat is the rightmost window, so it never gets capped and its
;; `word-wrap' lines run to the window edge.  Margin capping keeps the window
;; at whatever width the layout wants and shrinks the TEXT AREA to
;; `prettify-width' instead, absorbing the surplus into the right margin.
;; Width-aware machinery keeps working because `window-width' excludes
;; margins, so eca's `---' rule and `eca-table' follow the capped column.

(define-minor-mode margin-cap-mode
  "Cap this buffer's text area to `prettify-width' using window margins.

Like `center-buffer-mode' the flag is pure intent: `margin-cap-adjust'
manages the margins from the global window hooks, so the cap tracks
resizes, re-displays, and windows the buffer appears in later.

Supersedes `center-buffer-mode' rather than coexisting with it: capping
bounds BOTH sides and centers itself when full-width, so enabling this
mode turns plain centering off and `center-buffer--center-when-single'
skips capped buffers, which keeps a solo layout from undoing the right
bound.

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
`window-state-change-functions', so a chat window created by
`display-buffer', resized by a split, or re-shown from the buffer list
all get the cap without per-window bookkeeping.  Idempotent: the
available width is computed as body + current margins, so re-running on
an already-capped window sets the same margins rather than compounding.

Placement mirrors centering: a full-width window centers the column with
`center-buffer--pad-width', a tiled window hugs left.  Either way the
right margin absorbs the rest.  The mode/header/tab-line pads ride the
live margin, self-collapsing in the hug-left case."
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
  "Zero capped/centered margins in WINDOW's subtree before `split-window'.
`split-window' treats margins as fixed width, so a window whose margins
absorb most of the frame (a capped OR centered buffer) is \"too small
for splitting\" even when the underlying window is huge.  Dropping the
margins just before the split fixes that; the reactive adjust passes
re-assert the correct margins on the next configuration change.

WINDOW may be an INTERNAL window: `ck/spawn-right' splits a whole
vertical band, and the margins that block the split live on the band's
live child panes, not on the band window itself.  `walk-window-subtree'
visits every live leaf, so both the live-target split and the whole-band
split get cleared."
  (let ((root (if (windowp window) window (selected-window))))
    (when (window-valid-p root)
      (walk-window-subtree
       (lambda (w)
         (when (with-current-buffer (window-buffer w)
                 (or margin-cap-mode center-buffer-mode))
           (set-window-margins w 0 0)))
       root))))

;; `advice-add' dedupes by symbol, so re-loading does not stack advice.
(advice-add 'split-window :before #'margin-cap--reset-margins-for-split)

;; The eca chat opts into BOTH: window capping snaps a tiled chat window down
;; to the reading column so the sibling gets the surplus, and margin capping
;; covers what the snap cannot reach (a full-width chat window with no
;; sibling to donate space to).  On a snapped window the cap collapses to zero.
(add-hook 'eca-chat-mode-hook #'margin-cap-mode)

(provide 'config/modes/prettify-mode)
