;; -*- lexical-binding: t; -*-
;;; Markdown table handling for ECA chat buffers -----------------------------
;;
;; Two features: re-aligning every table in the chat (ECA only aligns the
;; just-finished turn) and a dedicated wrapped reading view for wide tables.

(require 'prelude)
(require 'cl-lib)

(declare-functions "eca-table"
  eca-table-align
  eca-table-beautify)
(declare-functions "eca-chat"
  eca-chat--prompt-area-start-point)
(declare-functions "markdown-mode"
  markdown-table-at-point-p
  markdown-table-begin
  markdown-table-end)
(declare-vars eca-chat-table-beautify)

(defcustom ck/eca-chat-auto-align-tables t
  "When non-nil, re-align all markdown tables after each ECA response finishes.
ECA only aligns the just-finished turn, so tables outside that window (earlier
turns, re-renders) stay raw and jagged.  This re-runs ECA's own aligner over
the whole chat content area to keep every table consistent.  Disable if it
ever perturbs ECA's overlays."
  :type 'boolean
  :group 'ck/eca)

;;; Table font --------------------------------------------------------------
;;
;; ECA remaps `markdown-table-face' to inherit `fixed-pitch' so tables align in
;; a monospace, but `fixed-pitch' resolves to the generic "Monospace" family,
;; not the chat's own font.  Pin tables to an explicit family instead.  The
;; remap is installed from `eca-chat-mode-hook', which runs after ECA's own
;; `markdown-table-face' remap in the mode body, so this later relative remap
;; wins on `:family' (last relative remap has highest priority) while ECA keeps
;; owning alignment and the colour/zebra overlays layered on top.

(defcustom ck/eca-chat-table-font "Go Mono"
  "Monospace family for markdown tables in ECA chat buffers.
Set to nil, or to a family with no installed font, to keep ECA's default
\(fixed-pitch).  Must be monospace or tables will not line up."
  :type '(choice (const :tag "ECA default (fixed-pitch)" nil) string)
  :group 'ck/eca)

(defun ck/eca-chat--table-font-available-p ()
  "Non-nil when `ck/eca-chat-table-font' is set and its font is installed."
  (and ck/eca-chat-table-font
       (find-font (font-spec :family ck/eca-chat-table-font))))

(defun ck/eca-chat--apply-table-font ()
  "Render markdown tables in this ECA chat buffer in `ck/eca-chat-table-font'.
A buffer-local relative remap on `markdown-table-face'; ECA's colour and zebra
overlays sit on top and specify no family, so they inherit this one and only
the table font changes.  A no-op when the configured font is unavailable."
  (when (ck/eca-chat--table-font-available-p)
    (face-remap-add-relative 'markdown-table-face
                             `(:family ,ck/eca-chat-table-font))))

;;; Table alignment ---------------------------------------------------------
;;
;; ECA aligns markdown tables only within the just-finished turn, so a table
;; that falls outside that window stays raw and jagged.  Re-run ECA's own
;; aligner/beautifier over the whole chat content area to keep every table
;; consistent.  The operation is idempotent on already-aligned tables.

(defun ck/eca-chat-align-tables (&optional beg end)
  "Align and beautify markdown tables in the current ECA chat buffer.
With no region (interactive use) aligns the whole content area.  BEG/END
bound the pass so callers can scope it: ECA's `eca-table-align' re-processes
its whole region from scratch with no early-out, so a whole-buffer pass is
O(history) and froze Emacs ~1.3s on large chats.  The finish-time auto-align
scopes to just the new turn instead."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let ((inhibit-read-only t)
        (beg (or beg (point-min)))
        (end (or end (eca-chat--prompt-area-start-point))))
    (eca-table-align beg end)
    (when (bound-and-true-p eca-chat-table-beautify)
      (eca-table-beautify beg end))))

(defun ck/eca-chat--auto-align-tables ()
  "Re-align the just-finished turn's tables on response completion.
Scoped to the finished turn (from `eca-chat--last-user-message-pos', mirroring
`ck/eca-chat--auto-preview-latex' and ECA's own end-of-stream scoping) so cost
does not grow with chat history.  A whole-buffer align runs ECA's O(history)
aligner and froze Emacs ~1.3s on large chats."
  (when (and ck/eca-chat-auto-align-tables (derived-mode-p 'eca-chat-mode))
    (ignore-errors
      (ck/eca-chat-align-tables
       (or (bound-and-true-p eca-chat--last-user-message-pos) (point-min))
       (eca-chat--prompt-area-start-point)))))

;;; Table wrapping (dedicated reading view) ---------------------------------
;;
;; Wide markdown tables read poorly inline (they wrap jaggedly).  Reflow the
;; table at point into a monospace `*eca-table*' buffer, word-wrapping long
;; cells so the whole table fits within `ck/eca-chat-table-wrap-width' columns.
;; The chat buffer is never modified, and this is self-contained (no dependence
;; on ECA's table internals, only stable markdown-mode boundary detection).

(defcustom ck/eca-chat-table-wrap-width 80
  "Target maximum total width for the wrapped table reading view."
  :type 'integer
  :group 'ck/eca)

(defun ck/eca-chat--table-line-p ()
  "Non-nil when the current line looks like a markdown table row."
  (let ((l (buffer-substring-no-properties (line-beginning-position)
                                           (line-end-position))))
    (and (not (string-blank-p l))
         (string-match-p "|" l))))

(defun ck/eca-chat--table-bounds-by-scan ()
  "Find a contiguous block of pipe-delimited lines around point.
Robust fallback for when `markdown-table-at-point-p' misfires (for example
when the table is mis-detected as a code block).  Blank lines bound it."
  (save-excursion
    (beginning-of-line)
    (when (ck/eca-chat--table-line-p)
      (let ((beg (line-beginning-position))
            (end (line-end-position)))
        (while (and (zerop (forward-line -1)) (ck/eca-chat--table-line-p))
          (setq beg (line-beginning-position)))
        (goto-char end)
        (while (and (zerop (forward-line 1)) (ck/eca-chat--table-line-p))
          (setq end (line-end-position)))
        (cons beg end)))))

(defun ck/eca-chat--table-bounds ()
  "Return (BEG . END) for the markdown table at point, or nil.
Tries markdown-mode detection, then ECA's table overlays, then a direct
line scan so it still works when markdown-mode fails to see the table."
  (or (and (markdown-table-at-point-p)
           (cons (markdown-table-begin) (markdown-table-end)))
      (when-let* ((ov (seq-find (lambda (o)
                                  (or (overlay-get o 'eca-table-action)
                                      (overlay-get o 'eca-table-overlay)))
                                (overlays-at (point)))))
        (cons (overlay-start ov) (overlay-end ov)))
      (ck/eca-chat--table-bounds-by-scan)))

(defun ck/eca-chat--table-split-row (line)
  "Split markdown table LINE into a list of trimmed cell strings.
Escaped pipes (\\|) are preserved as literal pipes."
  (let* ((s (replace-regexp-in-string "\\\\|" "\0" (string-trim line)))
         (s (replace-regexp-in-string "\\`|" "" s))
         (s (replace-regexp-in-string "|\\'" "" s)))
    (mapcar (lambda (c)
              (string-trim (replace-regexp-in-string "\0" "|" c)))
            (split-string s "|"))))

(defun ck/eca-chat--table-separator-p (cells)
  "Non-nil when CELLS form a markdown separator row."
  (and cells
       (cl-every (lambda (c) (string-match-p "\\`:?-+:?\\'" (string-trim c)))
                 cells)))

(defun ck/eca-chat--table-cell-align (cell)
  "Return the alignment symbol encoded by separator CELL."
  (let ((s (string-trim cell)))
    (cond ((and (string-prefix-p ":" s) (string-suffix-p ":" s)) 'center)
          ((string-suffix-p ":" s) 'right)
          ((string-prefix-p ":" s) 'left)
          (t 'left))))

(defun ck/eca-chat--wrap-cell (text width)
  "Word-wrap TEXT to WIDTH columns, hard-breaking any overlong word."
  (let ((lines (if (<= (string-width text) width)
                   (list text)
                 (with-temp-buffer
                   (insert text)
                   (let ((fill-column (max 1 width)))
                     (fill-region (point-min) (point-max)))
                   (split-string (buffer-string) "\n")))))
    (apply #'append
           (mapcar (lambda (ln)
                     (let (out)
                       (while (> (length ln) width)
                         (push (substring ln 0 width) out)
                         (setq ln (substring ln width)))
                       (push ln out)
                       (nreverse out)))
                   lines))))

(defun ck/eca-chat--pad-cell (s width align)
  "Pad S to WIDTH columns honoring ALIGN."
  (let ((pad (max 0 (- width (string-width s)))))
    (pcase align
      ('right  (concat (make-string pad ?\s) s))
      ('center (let ((l (/ pad 2)))
                 (concat (make-string l ?\s) s (make-string (- pad l) ?\s))))
      (_       (concat s (make-string pad ?\s))))))

(defun ck/eca-chat--sep-cell (width align)
  "Build a separator cell of WIDTH dashes with ALIGN markers."
  (pcase align
    ('center (concat ":" (make-string (max 1 (- width 2)) ?-) ":"))
    ('right  (concat (make-string (max 1 (- width 1)) ?-) ":"))
    ('left   (concat ":" (make-string (max 1 (- width 1)) ?-)))
    (_       (make-string (max 1 width) ?-))))

(defun ck/eca-chat--table-column-widths (rows ncols target)
  "Return capped widths for NCOLS columns of ROWS, total near TARGET.
Shrinks the widest columns first, never below a small minimum."
  (let ((widths (make-vector ncols 1)))
    (dotimes (ci ncols)
      (aset widths ci
            (apply #'max 1 (mapcar (lambda (r) (string-width (or (nth ci r) "")))
                                   rows))))
    (let* ((overhead (+ 1 (* 3 ncols)))
           (content-target (max (* ncols 3) (- target overhead)))
           (minw 3)
           (changed t))
      (while (and changed (> (apply #'+ (append widths nil)) content-target))
        (setq changed nil)
        (let ((widest 0) (wi -1))
          (dotimes (ci ncols)
            (when (> (aref widths ci) widest)
              (setq widest (aref widths ci) wi ci)))
          (when (and (>= wi 0) (> (aref widths wi) minw))
            (aset widths wi (1- (aref widths wi)))
            (setq changed t)))))
    (append widths nil)))

(defun ck/eca-chat--reflow-table (text target)
  "Reflow markdown table TEXT, word-wrapping cells to fit TARGET columns."
  (let* ((lines (split-string text "\n" t "[ \t]*"))
         (parsed (mapcar #'ck/eca-chat--table-split-row lines))
         (sep-idx (cl-position-if #'ck/eca-chat--table-separator-p parsed))
         (aligns (and sep-idx
                      (mapcar #'ck/eca-chat--table-cell-align
                              (nth sep-idx parsed))))
         (rows (cl-loop for r in parsed for i from 0
                        unless (and sep-idx (= i sep-idx)) collect r))
         (ncols (apply #'max 1 (mapcar #'length rows)))
         (aligns (append aligns
                         (make-list (max 0 (- ncols (length aligns))) 'left)))
         (widths (ck/eca-chat--table-column-widths rows ncols target)))
    (with-temp-buffer
      (cl-loop
       for r in rows for ridx from 0 do
       (let* ((cells (append r (make-list (max 0 (- ncols (length r))) "")))
              (frags (cl-loop for ci from 0 below ncols
                              collect (ck/eca-chat--wrap-cell
                                       (nth ci cells) (nth ci widths))))
              (nlines (apply #'max 1 (mapcar #'length frags))))
         (dotimes (k nlines)
           (insert "|")
           (dotimes (ci ncols)
             (insert " "
                     (ck/eca-chat--pad-cell (or (nth k (nth ci frags)) "")
                                            (nth ci widths) (nth ci aligns))
                     " |"))
           (insert "\n"))
         (when (= ridx 0)
           (insert "|")
           (dotimes (ci ncols)
             (insert " "
                     (ck/eca-chat--sep-cell (nth ci widths) (nth ci aligns))
                     " |"))
           (insert "\n"))))
      (buffer-string))))

(defun ck/eca-chat-open-table-wrapped ()
  "Open the markdown table at point in a wrapped, monospace reading buffer.
Long cells are word-wrapped so the table fits `ck/eca-chat-table-wrap-width'
columns.  The chat buffer is not modified."
  (interactive)
  (require 'markdown-mode)
  (let ((bounds (ck/eca-chat--table-bounds)))
    (unless bounds
      (user-error "Point is not on a markdown table"))
    (let* ((text (buffer-substring-no-properties (car bounds) (cdr bounds)))
           (wrapped (ck/eca-chat--reflow-table text ck/eca-chat-table-wrap-width))
           (buf (get-buffer-create "*eca-table*")))
      (with-current-buffer buf
        (special-mode)
        (if (ck/eca-chat--table-font-available-p)
            (buffer-face-set (list :family ck/eca-chat-table-font))
          (buffer-face-set 'fixed-pitch))
        (setq-local truncate-lines nil)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert wrapped)
          (goto-char (point-min))))
      (pop-to-buffer buf))))

(provide 'config/services/eca/tables)
