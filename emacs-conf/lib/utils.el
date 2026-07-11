;; -*- lexical-binding: t; -*-
;; Cross-cutting, area-agnostic operations (library, not application).  NOT in
;; the m-require boot chain: it has no load-time side effects, so consumers pull
;; it on demand with `(require 'lib/utils)'.  Uses uuidgen-4 from prelude.
(require 'prelude)

(declare-functions "cider" cider-sexp-at-point)

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
