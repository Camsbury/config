;; -*- lexical-binding: t; -*-
;; Cross-cutting, area-agnostic operations (library, not application).  NOT in
;; the m-require boot chain: it has no load-time side effects, so consumers pull
;; it on demand with `(require 'lib/utils)'.  Uses uuidgen-4 from prelude.
(require 'prelude)

(declare-functions "cider" cider-sexp-at-point)
(declare-functions "evil-commands" evil-window-left evil-window-right)

(defun ck/random-uuid ()
  "Returns a random UUID V4"
  (interactive)
  (kill-new (uuidgen-4)))

(defun ck/file-to-string (file-name)
  (with-temp-buffer
    (insert-file-contents file-name)
    (buffer-string)))

(defun ck/delete-file-and-buffer ()
  "Kill the current buffer and deletes the file it is visiting."
  (interactive)
  (let ((filename (buffer-file-name)))
    (if filename
        (if (y-or-n-p (concat "Do you really want to delete file " filename " ?"))
            (progn
              (delete-file filename)
              (message "Deleted file %s." filename)
              (kill-buffer)))
      (message "Not a file visiting buffer!"))))

(defun ck/lisp-eval-sexp-at-point ()
  "Evaluate the expression around point, like CIDER does."
  (interactive)
  (save-excursion
    (goto-char (cadr (cider-sexp-at-point 'bounds)))
    (call-interactively #'eval-last-sexp)))

(defun ck/set-window-width (window count)
  "Set the reading-column width of WINDOW's vertical band to COUNT columns.
Climbs from WINDOW to its enclosing band -- the nearest ancestor that is
horizontally combined with its siblings (a column in the row of bands) --
and moves that band's right edge.  This is what lets a stacked top/bottom
band resize as a UNIT: its panes are combined vertically, so resizing a
pane directly no-ops (a pane has no right edge to donate across), while
the band above them does.  No-op when the band is rightmost (no sibling
to donate/absorb the difference).

Measures a live LEAF of the band itself (descending via `window-child'),
not `frame-first-window', which returns the whole FRAME's first window:
when the band is not leftmost that would measure a DIFFERENT band, and if
that band already sits at COUNT the delta is zero and this band is
silently skipped (the bug that let a non-leftmost stacked band go
uncapped)."
  (let ((band window))
    (while (and band (not (window-combined-p band t)))
      (setq band (window-parent band)))
    (when (and band (window-next-sibling band))
      (let ((leaf band))
        (while (not (window-live-p leaf))
          (setq leaf (window-child leaf)))
        (ignore-errors
          (adjust-window-trailing-edge
           band (- count (window-body-width leaf)) t))))))

(defvar ck/window-band-last-selected (make-hash-table :test 'eq)
  "Maps a vertical-band root window to the pane last selected within it.
Populated by `ck/window-left'/`ck/window-right' (bound to s-h/s-l in
`core/desktop.el') so returning to a multi-pane band (a stacked top/bottom
split) restores whichever pane you were last on. Plain `evil-window-left'/
`evil-window-right' (windmove underneath) do not do this: a full-height
neighboring band overlaps both stacked panes equally, so ties resolve by
window-list order and always land on the same pane (typically the top
one), regardless of which pane you left from.")

(defun ck/window-band-root (&optional window)
  "Return the vertical-band root window containing WINDOW.
Climbs past any top/bottom (vertical) combination to the child of the
row-of-bands, or the frame root when no bands exist yet. Mirrors
`ck/band-window' in `config/navigation.el' (kept separate here: `lib/'
cannot depend on `config/', decision 0009's library/application seam)."
  (let ((w (or window (selected-window))))
    (while (let ((p (window-parent w)))
             (and p (not (window-left-child p))))
      (setq w (window-parent w)))
    w))

(defun ck/window-move-remembering-band (command)
  "Run directional-movement COMMAND, remembering per-band pane focus.
Records the departing window against its band before running COMMAND (via
`call-interactively', so COMMAND's own interactive spec and count argument
still apply), then, if the band just entered has a remembered pane still
live inside it, selects that pane instead of wherever COMMAND landed. See
`ck/window-band-last-selected' for why this is needed."
  (let* ((from (selected-window))
         (from-band (ck/window-band-root from)))
    (call-interactively command)
    (let* ((target-band (ck/window-band-root))
           (remembered (gethash target-band ck/window-band-last-selected)))
      (puthash from-band from ck/window-band-last-selected)
      (when (and remembered
                 (window-live-p remembered)
                 (eq (ck/window-band-root remembered) target-band)
                 (not (eq remembered (selected-window))))
        (select-window remembered)))))

(defun ck/window-left ()
  "Move focus left by band, restoring that band's last-selected pane."
  (interactive)
  (ck/window-move-remembering-band #'evil-window-left))

(defun ck/window-right ()
  "Move focus right by band, restoring that band's last-selected pane."
  (interactive)
  (ck/window-move-remembering-band #'evil-window-right))

(defun ck/shuffle-selection (beginning end)
  "Shuffle the current selection"
  (interactive "r")
  (shell-command-on-region beginning end "shuf" nil t))

(defun ck/completing-read-in-order (prompt candidates &rest args)
  "`completing-read' over CANDIDATES preserving their given order.
The default completion UI re-sorts candidates (history, then length, then
alpha); this pins `display-sort-function' to identity so callers whose
candidate order carries meaning (a server catalog, a preselected head
candidate) render as passed.  ARGS are the remaining `completing-read'
arguments after COLLECTION (predicate, require-match, ...)."
  (apply #'completing-read prompt
         (lambda (string pred action)
           (if (eq action 'metadata)
               '(metadata (display-sort-function . identity)
                          (cycle-sort-function . identity))
             (complete-with-action action candidates string pred)))
         args))

(defun ck/minor-mode-active-p (minor-mode)
  "Check if the passed minor-mode is active"
  (->> minor-mode-list
    (--filter
     (and
      (boundp it)
      (symbol-value it)))
    (--filter
     (eq it minor-mode))
    null
    not))

(defun ck/unescape-clipboard-string ()
  "Unescape the current clipboard string and replace it back onto the clipboard."
  (interactive)
  (let ((current-clipboard (current-kill 0 t)))
    (kill-new (read current-clipboard))))

(provide 'lib/utils)
