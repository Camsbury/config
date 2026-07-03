;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/bindings)
(require 'color)
(require 'cl-lib)

;; Functions/vars provided at runtime by `eca' / `markdown-mode'; forward-declared
;; so byte-compiling the helpers below stays warning-free without force-loading.
(declare-function eca-table-align "eca-table")
(declare-function eca-table-beautify "eca-table")
(declare-function eca-chat--prompt-area-start-point "eca-chat")
(declare-function markdown-table-at-point-p "markdown-mode")
(declare-function markdown-table-begin "markdown-mode")
(declare-function markdown-table-end "markdown-mode")
(defvar eca-chat-table-beautify)

;;; LaTeX preview in chat buffers ------------------------------------------
;;
;; ECA chat buffers derive from `gfm-mode', so model output containing LaTeX
;; (the illegible `\frac{...}` paste problem) shows up as raw text.  We render
;; each math fragment with the system TeX toolchain and overlay the image in
;; place.  Self-contained: no org, no extra packages, just binaries on PATH.
;; Vector SVG via `dvisvgm' is preferred; raster PNG via `dvipng' is the
;; fallback.  Fragment color is carried into the document with `xcolor', which
;; both backends honor.
;;
;; Delimiter styles handled: $$...$$, \[...\], \(...\), \begin{..}..\end{..},
;; and (strictly, to avoid currency/shell false positives) $...$.

(defgroup ck/eca nil
  "Personal ECA chat customizations."
  :group 'cmacs)

(defcustom ck/eca-chat-latex-image-dir
  (expand-file-name "eca-ltximg/" user-emacs-directory)
  "Directory for cached LaTeX preview images.
Images are content-hashed, so this doubles as a cross-session cache."
  :type 'directory
  :group 'ck/eca)

(defcustom ck/eca-chat-latex-format 'svg
  "Preferred image format for LaTeX previews.
`svg' renders crisp vectors via dvisvgm; `png' rasterizes via dvipng.
Falls back to png when dvisvgm or svg image support is unavailable."
  :type '(choice (const svg) (const png))
  :group 'ck/eca)

(defcustom ck/eca-chat-latex-dpi 140
  "Resolution for PNG previews (used only by the dvipng fallback)."
  :type 'integer
  :group 'ck/eca)

(defcustom ck/eca-chat-auto-latex t
  "When non-nil, render LaTeX automatically after each ECA response finishes."
  :type 'boolean
  :group 'ck/eca)

(defcustom ck/eca-chat-auto-align-tables t
  "When non-nil, re-align all markdown tables after each ECA response finishes.
ECA only aligns the just-finished turn, so tables outside that window (earlier
turns, re-renders) stay raw and jagged.  This re-runs ECA's own aligner over
the whole chat content area to keep every table consistent.  Disable if it
ever perturbs ECA's overlays."
  :type 'boolean
  :group 'ck/eca)

;;; Rendering core ----------------------------------------------------------

(defun ck/eca-chat--effective-format ()
  "Return the format actually usable now: `svg' if possible, else `png'."
  (if (and (eq ck/eca-chat-latex-format 'svg)
           (image-type-available-p 'svg)
           (executable-find "dvisvgm"))
      'svg 'png))

(defun ck/eca-chat--fg-rgb ()
  "Return the default foreground as an (R G B) list of 0..1 floats."
  (or (color-name-to-rgb (or (face-foreground 'default nil t) "black"))
      '(0.0 0.0 0.0)))

(defun ck/eca-chat--latex-document (fragment rgb)
  "Wrap FRAGMENT (delimiters included) in a minimal LaTeX doc colored RGB."
  (format (concat
           "\\documentclass[12pt]{article}\n"
           "\\usepackage{amsmath}\n"
           "\\usepackage{amssymb}\n"
           "\\usepackage{xcolor}\n"
           "\\pagestyle{empty}\n"
           "\\begin{document}\n"
           "\\color[rgb]{%.3f,%.3f,%.3f}%%\n"
           "%s\n"
           "\\end{document}\n")
          (nth 0 rgb) (nth 1 rgb) (nth 2 rgb) fragment))

(defun ck/eca-chat--render-fragment (fragment rgb)
  "Compile FRAGMENT (colored RGB) to an image; return its path or nil.
Output is SVG (dvisvgm) or PNG (dvipng) per `ck/eca-chat--effective-format',
cached on disk by a hash of FRAGMENT, color, DPI and format."
  (let* ((dir ck/eca-chat-latex-image-dir)
         (dpi ck/eca-chat-latex-dpi)
         (fmt (ck/eca-chat--effective-format))
         (key (secure-hash 'sha1 (format "%s|%S|%d|%s" fragment rgb dpi fmt)))
         (out (expand-file-name (concat key "." (symbol-name fmt)) dir)))
    (unless (file-exists-p out)
      (let ((tex (expand-file-name (concat key ".tex") dir))
            (dvi (expand-file-name (concat key ".dvi") dir)))
        (with-temp-file tex
          (insert (ck/eca-chat--latex-document fragment rgb)))
        (when (zerop (call-process "latex" nil nil nil
                                   "-interaction=nonstopmode" "-halt-on-error"
                                   "-output-directory" dir tex))
          (pcase fmt
            ('svg (call-process "dvisvgm" nil nil nil
                                "--no-fonts" "--exact" "--bbox=min"
                                "-o" out dvi))
            ('png (call-process "dvipng" nil nil nil
                                "-D" (number-to-string dpi)
                                "-T" "tight" "-bg" "Transparent"
                                "-o" out dvi))))
        ;; Clean intermediates; the rendered image is the only artifact we keep.
        (dolist (ext '(".tex" ".dvi" ".aux" ".log"))
          (ignore-errors (delete-file (expand-file-name (concat key ext) dir))))))
    (and (file-exists-p out) out)))

;;; Overlay management ------------------------------------------------------

(defun ck/eca-chat--latex-overlays (beg end)
  "Return our LaTeX preview overlays between BEG and END."
  (seq-filter (lambda (ov) (overlay-get ov 'ck/eca-latex))
              (overlays-in beg end)))

(defun ck/eca-chat--in-code-p (pos)
  "Non-nil when POS sits inside markdown code (a fenced block or inline span).
Guards against rendering shell vars / code samples that merely look like math."
  (save-excursion
    (goto-char pos)
    (or (and (fboundp 'markdown-code-block-at-point-p)
             (markdown-code-block-at-point-p))
        (and (fboundp 'markdown-inline-code-at-point-p)
             (markdown-inline-code-at-point-p)))))

(defun ck/eca-chat--render-at (mbeg mend rgb)
  "Render the fragment between MBEG and MEND in color RGB, unless skippable."
  (unless (or (ck/eca-chat--in-code-p mbeg)
              (ck/eca-chat--latex-overlays mbeg mend))
    (let* ((frag (buffer-substring-no-properties mbeg mend))
           (img (ck/eca-chat--render-fragment frag rgb)))
      (when img
        (let ((ov (make-overlay mbeg mend)))
          (overlay-put ov 'ck/eca-latex t)
          (overlay-put ov 'evaporate t)
          (overlay-put ov 'help-echo frag)
          (overlay-put ov 'display
                       (create-image img nil nil :ascent 'center)))))))

;;; Scanning ----------------------------------------------------------------

(defun ck/eca-chat--render-delim (open close beg end rgb)
  "Render OPEN...CLOSE delimited fragments (literal strings) in BEG..END."
  (save-excursion
    (goto-char beg)
    (while (search-forward open end t)
      (let ((mbeg (match-beginning 0)))
        (if (search-forward close end t)
            (ck/eca-chat--render-at mbeg (point) rgb)
          (goto-char end))))))

(defun ck/eca-chat--render-environments (beg end rgb)
  "Render \\begin{env}...\\end{env} blocks in BEG..END."
  (save-excursion
    (goto-char beg)
    (while (re-search-forward "\\\\begin{\\([a-zA-Z*]+\\)}" end t)
      (let ((mbeg (match-beginning 0))
            (env (match-string 1)))
        (if (re-search-forward (concat "\\\\end{" (regexp-quote env) "}") end t)
            (ck/eca-chat--render-at mbeg (point) rgb)
          (goto-char end))))))

(defun ck/eca-chat--render-single-dollar (beg end rgb)
  "Render strict $...$ inline math in BEG..END.
Rejects spacing/digit patterns typical of currency and shell variables."
  (save-excursion
    (goto-char beg)
    (while (re-search-forward "\\$\\([^ \t\r\n$][^$\n]*?\\)\\$" end t)
      (let ((mb (match-beginning 0))
            (me (match-end 0)))
        (unless (or (eq (char-before mb) ?$)                 ; part of $$
                    (memq (char-after me) '(?$ ?0 ?1 ?2 ?3 ?4 ?5 ?6 ?7 ?8 ?9))
                    (memq (char-before (1- me)) '(?\s ?\t))) ; space before close
          (ck/eca-chat--render-at mb me rgb))))))

(defun ck/eca-chat--render-region (beg end rgb)
  "Render every supported LaTeX form in BEG..END (longest delimiters first)."
  (ck/eca-chat--render-delim "$$" "$$" beg end rgb)
  (ck/eca-chat--render-delim "\\[" "\\]" beg end rgb)
  (ck/eca-chat--render-delim "\\(" "\\)" beg end rgb)
  (ck/eca-chat--render-environments beg end rgb)
  (ck/eca-chat--render-single-dollar beg end rgb))

;;; Commands ----------------------------------------------------------------

(defun ck/eca-chat-preview-latex (&optional beg end)
  "Render LaTeX fragments as inline images in the current ECA chat buffer.
Operates on the active region when there is one, otherwise the whole buffer.
Fragments inside markdown code are left as text."
  (interactive (when (use-region-p)
                 (list (region-beginning) (region-end))))
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (unless (and (executable-find "latex")
               (or (executable-find "dvisvgm") (executable-find "dvipng")))
    (user-error "Need `latex' plus `dvisvgm' or `dvipng' on PATH"))
  (make-directory ck/eca-chat-latex-image-dir t)
  (let ((beg (or beg (point-min)))
        (end (or end (point-max)))
        (rgb (ck/eca-chat--fg-rgb)))
    ;; Keep markdown's code-block syntax current so the guard is reliable.
    (syntax-propertize end)
    (ck/eca-chat--render-region beg end rgb)))

(defun ck/eca-chat-clear-latex (&optional beg end)
  "Remove LaTeX preview images from the current ECA chat buffer."
  (interactive (when (use-region-p)
                 (list (region-beginning) (region-end))))
  (dolist (ov (ck/eca-chat--latex-overlays (or beg (point-min))
                                           (or end (point-max))))
    (delete-overlay ov)))

(defun ck/eca-chat-toggle-latex ()
  "Toggle LaTeX previews across the current ECA chat buffer."
  (interactive)
  (if (ck/eca-chat--latex-overlays (point-min) (point-max))
      (ck/eca-chat-clear-latex (point-min) (point-max))
    (ck/eca-chat-preview-latex (point-min) (point-max))))

(defun ck/eca-chat--auto-preview-latex ()
  "Render LaTeX on response completion when `ck/eca-chat-auto-latex' is set.
Scoped to the just-finished turn (mirroring ECA's own end-of-stream
scoping) so cost does not grow with chat history and so turns the user
manually cleared are not re-rendered."
  (when (and ck/eca-chat-auto-latex (derived-mode-p 'eca-chat-mode))
    (ignore-errors
      (ck/eca-chat-preview-latex
       (or (bound-and-true-p eca-chat--last-user-message-pos) (point-min))
       (point-max)))))

;;; Table alignment ---------------------------------------------------------
;;
;; ECA aligns markdown tables only within the just-finished turn, so a table
;; that falls outside that window stays raw and jagged.  Re-run ECA's own
;; aligner/beautifier over the whole chat content area to keep every table
;; consistent.  The operation is idempotent on already-aligned tables.

(defun ck/eca-chat-align-tables ()
  "Align and beautify every markdown table in the current ECA chat buffer."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let ((inhibit-read-only t)
        (end (eca-chat--prompt-area-start-point)))
    (eca-table-align (point-min) end)
    (when (bound-and-true-p eca-chat-table-beautify)
      (eca-table-beautify (point-min) end))))

(defun ck/eca-chat--auto-align-tables ()
  "Re-align all chat tables on response completion when enabled."
  (when (and ck/eca-chat-auto-align-tables (derived-mode-p 'eca-chat-mode))
    (ignore-errors (ck/eca-chat-align-tables))))

;;; Table wrapping (dedicated reading view) ---------------------------------
;;
;; Wide markdown tables read poorly inline (they wrap jaggedly).  Reflow the
;; table at point into a fixed-pitch `*eca-table*' buffer, word-wrapping long
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
  "Open the markdown table at point in a wrapped, fixed-pitch reading buffer.
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
        (buffer-face-set 'fixed-pitch)
        (setq-local truncate-lines nil)
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert wrapped)
          (goto-char (point-min))))
      (pop-to-buffer buf))))

;;; Closed-buffer sweeping ---------------------------------------------------
;;
;; ECA renames buffers for dead sessions to "<eca ...:closed ...>" instead of
;; killing them, so chat and process-stderr buffers pile up across restarts.
;; Sweep them whenever a session winds down: after `eca-process-stop', after
;; `eca-chat-exit', and when a chat buffer is killed by hand.

(defvar ck/eca--sweeping nil
  "Reentrancy guard for `ck/eca--sweep-closed-buffers'.
The sweep kills buffers and also runs from `kill-buffer-hook', so without
the guard it would recurse into itself.")

(defun ck/eca--sweep-closed-buffers (&rest _)
  "Kill every closed ECA buffer (chat and process stderr)."
  (unless ck/eca--sweeping
    (let ((ck/eca--sweeping t))
      (dolist (buf (buffer-list))
        (when (and (buffer-live-p buf)
                   (string-match-p "^<eca.*:closed" (buffer-name buf)))
          (kill-buffer buf))))))

(defun ck/eca--sweep-on-chat-kill ()
  "Arrange a closed-buffer sweep when the current chat buffer is killed."
  (add-hook 'kill-buffer-hook #'ck/eca--sweep-closed-buffers nil t))

;;; Package setup -----------------------------------------------------------

(use-package eca
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  (eca-chat-mode . ck/eca--sweep-on-chat-kill)
  :config
  (setq eca-chat-use-side-window nil)

  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-preview-latex)
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-align-tables)

  (advice-add 'eca-process-stop :after #'ck/eca--sweep-closed-buffers)
  (advice-add 'eca-chat-exit    :after #'ck/eca--sweep-closed-buffers)

  (general-def 'normal eca-chat-mode-map
    [remap ck/empty-mode-leader]     #'hydra-eca/body))

(defhydra hydra-eca (:exit t :columns 5)
  "eca-chat-mode"
  ("c" #'eca-chat-clear "Clear the chat")
  ("a" #'eca-chat-select-agent "Select agent")
  ("m" #'eca-chat-select-model "Select the model")
  ("o" #'eca-chat-new "New chat")
  ("t" #'eca-chat-select "Select chat")
  ("n" #'eca-chat-rename "Rename chat")
  ("v" #'eca-chat-select-variant "Select the variant")
  ("l" #'ck/eca-chat-toggle-latex "Toggle LaTeX")
  ("L" #'ck/eca-chat-clear-latex "Clear LaTeX")
  ("b" #'ck/eca-chat-align-tables "Align tables")
  ("T" #'ck/eca-chat-open-table-wrapped "Open table (wrapped)"))



(provide 'config/services/eca)
