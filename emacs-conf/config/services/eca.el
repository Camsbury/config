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
(declare-function eca-chat--switch-windows-to-sibling "eca-chat")
(declare-function eca-chat--prompt-content "eca-chat")
(declare-function eca-chat--set-prompt "eca-chat")
(declare-function eca-chat--send-prompt "eca-chat")
(declare-function eca-chat--insert "eca-chat")
(declare-function eca-chat--point-at-prompt-field-p "eca-chat")
(declare-function gfm-mode "markdown-mode")
(declare-function evil-normal-state "evil-states")
(declare-function eca-config-updated "eca")
(declare-function eca-session "eca-util")
(declare-function eca-assert-session-running "eca-util")
(declare-function eca-api-request-sync "eca-api")
(declare-function tab-line-switch-to-next-tab "tab-line")
(declare-function tab-line-switch-to-prev-tab "tab-line")
(declare-function eca-api-request-async "eca-api")
(declare-function eca-chat--new-chat "eca-chat")
(declare-function eca-chat--get-last-buffer "eca-chat")
(declare-function eca-chat--set-chat-loading "eca-chat")
(declare-function eca-chat--model "eca-chat")
(declare-function eca-chat--agent "eca-chat")
(declare-function eca-chat-resume "eca-chat")
(defvar eca-chat--id)
(defvar eca-chat--closed)
(defvar eca-chat--last-request-id)
(defvar eca-chat--last-known-model)
(defvar eca-chat--last-known-agent)
(defvar eca-chat--last-known-variant)
(defvar eca-chat--last-known-trust)
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

;;; Tab management -----------------------------------------------------------
;;
;; Two closing flavors for the chat tab-line: close just the tab (buffer),
;; or close it and delete the chat server-side.  Cycling left/right is
;; stock `tab-line' -- ECA's tabs carry `buffer' entries, which
;; `tab-line-switch-to-{prev,next}-tab' understands, wrapping at the ends
;; via `tab-line-switch-cycling'.

(defun ck/eca-chat-close-tab ()
  "Close the current chat tab without deleting the chat server-side.
Reuses ECA's own kill-buffer path (sibling-window switch plus session
registry cleanup) but answers its \"delete from server?\" prompt with a
hard no, so the chat can still be resumed later."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  ;; `eca-chat--delete-chat' (on `kill-buffer-hook') only runs its cleanup
  ;; when `this-command' looks like a kill, and it prompts via `yes-or-no-p'
  ;; about server-side deletion; the chat buffer visits no file, so no other
  ;; prompt can be swallowed by the stub.
  (cl-letf (((symbol-function 'yes-or-no-p) (lambda (&rest _) nil)))
    (let ((this-command 'kill-buffer))
      (kill-buffer (current-buffer)))))

(defun ck/eca-chat-delete-tab ()
  "Close the current chat tab AND delete the chat from the server.
Unlike `eca-chat-delete' this always targets the current buffer's chat,
not the session's last-visited one.  Never prompts."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let ((session (eca-session))
        (buffer (current-buffer))
        (chat-id eca-chat--id))
    (eca-assert-session-running session)
    (if (not chat-id)
        (ck/eca-chat-close-tab)
      ;; Mark closed so the kill-buffer hook neither prompts nor sends a
      ;; second chat/delete; switch windows to a sibling chat first so the
      ;; chat window keeps showing a chat.
      (setq-local eca-chat--closed t)
      (eca-chat--switch-windows-to-sibling session buffer)
      (unwind-protect
          (eca-api-request-sync session
                                :method "chat/delete"
                                :params (list :chatId chat-id))
        (when (buffer-live-p buffer)
          (kill-buffer buffer))))))

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

;;; Window placement --------------------------------------------------------
;;
;; Scope chat window reuse to the ECA workspace (the bracketed session name in
;; the buffer name).  Chats from a workspace already on screen toggle into
;; that one window; a different workspace's chat gets its own window instead
;; of hijacking one already showing another session.

(defun ck/eca-chat--workspace-tag (buffer-or-name)
  "Return the \"[workspace]\" tag of an eca chat BUFFER-OR-NAME, or nil.
The tag is the bracketed ECA-session name in the buffer name, e.g.
\"[config]\" from \"<eca-chat[config]:2:7>\"."
  (let ((name (if (bufferp buffer-or-name) (buffer-name buffer-or-name)
                buffer-or-name)))
    (when (and name (string-match "\\`<eca-chat\\(\\[[^]]*\\]\\)" name))
      (match-string 1 name))))

(defun ck/eca-display-reuse-same-workspace-window (buffer alist)
  "`display-buffer' action: reuse a window showing BUFFER's ECA workspace.
Reuses a window on the selected frame already showing an `eca-chat-mode'
buffer whose workspace tag matches BUFFER's, so chats from the same ECA
session toggle in place while a different session gets its own window.
Returns the reused window, or nil to fall through to the next action."
  (when-let* ((tag (ck/eca-chat--workspace-tag buffer)))
    (when-let* ((win (catch 'found
                       (dolist (w (window-list (selected-frame) 'no-mini))
                         (let ((b (window-buffer w)))
                           (when (and (not (eq b buffer))
                                      (eq (buffer-local-value 'major-mode b)
                                          'eca-chat-mode)
                                      (equal (ck/eca-chat--workspace-tag b) tag))
                             (throw 'found w)))))))
      (window--display-buffer buffer win 'reuse alist)
      win)))

;;; Server-identified new chats ---------------------------------------------
;;
;; The ECA server only creates a chat record (`[:chats id]') on a chat's FIRST
;; `chat/prompt'.  A tab that has not yet been prompted is unknown server-side,
;; and the agent/model-change handlers then drop its chat-id and broadcast the
;; change session-wide -- so switching agent or model on a fresh tab clobbers
;; every other open chat.  We sidestep that by registering the chat up front:
;; fire one benign no-LLM slash command (`/costs' routes through the server's
;; command handler, which seeds the chat record and finishes idle without ever
;; calling a model).  Its short output stays on screen; since command output is
;; display-only (never persisted to the chat's messages), it neither pollutes
;; the LLM context nor needs clearing.

(defcustom ck/eca-chat-register-command "/costs"
  "Slash command used to register a new chat with the ECA server.
Must be a command the server answers WITHOUT calling an LLM -- it only needs
to make the server seed the chat record.  `/costs' is the lightest such
command: it reads a few usage counters, prints a short system message, and
finishes idle.  Command output is display-only (the server never adds it to
the chat's message list), so it does not leak into the LLM conversation and
is safe to leave on screen."
  :type 'string
  :group 'ck/eca)

(defun ck/eca--register-current-chat (session)
  "Register the current chat buffer with SESSION's server via a benign command.
Sends `ck/eca-chat-register-command' as a real `chat/prompt' carrying the
buffer's eager chat-id, which makes the server create its `[:chats id]'
record.  The command's short output is left on screen.  No-op without a
chat-id or on an already-closed buffer."
  (when (and eca-chat--id (not eca-chat--closed))
    ;; Flip loading so the turn renders like any normal command turn (spinner,
    ;; then a clean finish that fontifies the output and runs the finished-hook).
    (eca-chat--set-chat-loading session t)
    (eca-api-request-async
     session
     :method "chat/prompt"
     :params (list :message ck/eca-chat-register-command
                   :request-id (cl-incf eca-chat--last-request-id)
                   :chatId eca-chat--id
                   :model (eca-chat--model)
                   :agent (eca-chat--agent)
                   :contexts [])
     ;; The id is already buffer-local; the response carries nothing we need.
     :success-callback #'ignore)))

(defun ck/eca-chat-new-registered ()
  "Create a new ECA chat that is registered with the server immediately.
Unlike `eca-chat-new', the fresh tab is known server-side before its first
real prompt, so changing its agent or model is scoped to this tab alone and
no longer clobbers the other open chats."
  (interactive)
  (let ((session (eca-session)))
    (eca-assert-session-running session)
    (eca-chat--new-chat session)
    (when-let* ((buf (eca-chat--get-last-buffer session)))
      (with-current-buffer buf
        (ck/eca--register-current-chat session)))))

;;; Chat-scoped config isolation ---------------------------------------------
;;
;; Two upstream defects conspire to make "change agent/model on one tab"
;; leak into every other tab (verified against eca server 141.0 +
;; eca-emacs 20260629.1508); both are worked around here:
;;
;; 1. Wire mismatch (the big one): the server scopes a per-chat
;;    `config/updated' by putting `chatId' at the TOP LEVEL of the payload
;;    ({"chat": {...}, "chatId": "..."}, see the server's
;;    `notify-fields-changed-only!'), but `eca-config-updated' extracts only
;;    the inner `:chat' plist and passes that to `eca-chat-config-updated',
;;    dropping the id.  The chat handler therefore never sees a `chatId',
;;    always takes its legacy session-wide branch, and stomps every tab's
;;    buffer-local model/agent/variant.  Fix:
;;    `ck/eca--config-updated-attach-chat-id' re-attaches the top-level id
;;    onto the `:chat' plist before dispatch, so the upstream scoped branch
;;    (eca-emacs#231) finally runs.
;;
;; 2. Global fallback writes: `eca-chat--apply-per-chat-config' and the
;;    interactive selectors (`eca-chat--set-agent',
;;    `eca-chat-select-model', `eca-chat-select-variant') write the GLOBAL
;;    `eca-chat--last-known-{model,agent,variant,trust}' even for
;;    buffer-scoped changes.  Tabs whose buffer-local selection is nil
;;    display AND send those globals, so they silently follow.  Fix: shadow
;;    the globals (dynamic let) around scoped paths, so buffer-local writes
;;    land and global writes evaporate on exit.  Globals then change only
;;    on genuine session-wide broadcasts (post-initialize defaults), which
;;    also means a NEW tab inherits the session default rather than the
;;    last per-tab pick; that is the intended isolation semantics.
;;
;; Server-side scoping additionally requires the chat to EXIST in the
;; server db (an unknown id falls back to a session-wide broadcast by
;; design), hence the /costs registration above.  All three pieces are
;; needed.

(defun ck/eca--config-updated-attach-chat-id (fn session config)
  "Around-advice for `eca-config-updated' (FN, SESSION, CONFIG).
Re-attach the top-level `:chatId' onto the inner `:chat' plist, which is
where `eca-chat-config-updated' expects it; without this the scoped
branch never runs and per-chat updates broadcast to every tab."
  (let ((chat-id (plist-get config :chatId))
        (chat (plist-get config :chat)))
    (funcall fn session
             (if (and chat-id chat (not (plist-get chat :chatId)))
                 (plist-put (copy-sequence config) :chat
                            (append (list :chatId chat-id) chat))
               config))))

(defun ck/eca--shadow-config-globals (fn &rest args)
  "Around-advice shadowing the global last-known config fallbacks.
Runs FN with ARGS while the four `eca-chat--last-known-*' globals are
dynamically rebound, so a buffer-scoped selection cannot leak to other
tabs through the global fallback display path."
  (let ((eca-chat--last-known-model eca-chat--last-known-model)
        (eca-chat--last-known-agent eca-chat--last-known-agent)
        (eca-chat--last-known-variant eca-chat--last-known-variant)
        (eca-chat--last-known-trust eca-chat--last-known-trust))
    (apply fn args)))

(defun ck/eca--config-updated-guard-globals (fn session chat-config)
  "Around-advice for `eca-chat-config-updated' (FN, SESSION, CHAT-CONFIG).
Confine chat-scoped payloads (those carrying `chatId') to buffer-local
state by shadowing the global last-known fallbacks for the duration."
  (if (plist-get chat-config :chatId)
      (let ((eca-chat--last-known-model eca-chat--last-known-model)
            (eca-chat--last-known-agent eca-chat--last-known-agent)
            (eca-chat--last-known-variant eca-chat--last-known-variant)
            (eca-chat--last-known-trust eca-chat--last-known-trust))
        (funcall fn session chat-config))
    (funcall fn session chat-config)))

;;; Prompt compose buffer ----------------------------------------------------
;;
;; Editing the prompt in place is annoying: RET sends, and any evil edit risks
;; an accidental submit.  Borrowing the `string-edit-at-point' idea, pop the
;; current prompt text into a dedicated buffer where evil motions work freely
;; and RET is just a newline, then commit it back (optionally sending).  Only
;; the plain text round-trips; add `@'-contexts in the chat buffer itself.
;;
;; The commit/abort commands are intentionally left unbound -- bind them (or a
;; hydra) in `ck/eca-compose-mode-map' to taste.

(defvar-local ck/eca-compose--source-buffer nil
  "The `eca-chat-mode' buffer whose prompt this compose buffer edits.")

(defcustom ck/eca-compose-display-direction 'below
  "Direction in which the compose buffer splits off the chat window.
The split is confined to the chat window so it never touches the rest of
the tiling.  `below'/`above' stack them (compose under/over the chat);
`right'/`left' give a side-by-side split."
  :type '(choice (const right) (const left) (const below) (const above))
  :group 'ck/eca)

(defvar ck/eca-compose-mode-map (make-sparse-keymap)
  "Keymap for `ck/eca-compose-mode'.
`C-c C-c' toggles back to the chat (fill prompt, no send), `C-c C-s'
sends, `C-c C-k' aborts.")

(define-minor-mode ck/eca-compose-mode
  "Minor mode for the ECA prompt compose buffer."
  :lighter " eca-compose"
  :keymap ck/eca-compose-mode-map)

(defun ck/eca-chat-edit-prompt ()
  "Edit the current ECA chat prompt in a dedicated compose buffer.
Lifts the prompt text into a separate `gfm-mode' buffer where evil
motions work and RET is a plain newline, so there is no accidental send.
Commit with `ck/eca-compose-finish' (fill back only) or
`ck/eca-compose-send' (fill back and send); drop it with
`ck/eca-compose-abort'.  Only plain text round-trips; add `@'-contexts in
the chat buffer."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let ((src (current-buffer))
        (win (selected-window))
        (text (or (eca-chat--prompt-content) ""))
        (buf (get-buffer-create "*eca-compose*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer))
      (if (fboundp 'gfm-mode) (gfm-mode) (text-mode))
      (ck/eca-compose-mode 1)
      (setq-local ck/eca-compose--source-buffer src)
      (insert text)
      (goto-char (point-max))
      (when (bound-and-true-p evil-local-mode)
        (evil-normal-state)))
    ;; Split the chat window itself in the chosen direction, so the compose
    ;; window lives inside the chat's footprint and leaves the surrounding
    ;; tiling untouched (a plain `pop-to-buffer' would split an arbitrary
    ;; window).
    (pop-to-buffer buf
                   `((display-buffer-in-direction)
                     (direction . ,ck/eca-compose-display-direction)
                     (window . ,win)
                     ;; Give the compose window a usable share of the chat
                     ;; window rather than the tiny default split.  Only the
                     ;; entry matching the split axis is honored: `window-height'
                     ;; for below/above, `window-width' for left/right.
                     (window-height . 0.4)
                     (window-width . 0.5)
                     ;; Dedicated so killing the compose buffer on
                     ;; finish/abort deletes this window and the chat window
                     ;; reclaims the space, instead of leaving a stray split.
                     (dedicated . t)))))

(defun ck/eca-compose--text ()
  "Return the trimmed contents of the compose buffer."
  (string-trim (buffer-substring-no-properties (point-min) (point-max))))

(defun ck/eca-compose--commit (send)
  "Push the composed text into the source chat prompt; SEND it when non-nil.
Kills the compose buffer and selects the source chat window afterward."
  (unless ck/eca-compose--source-buffer
    (user-error "Not an ECA compose buffer"))
  (let ((src ck/eca-compose--source-buffer)
        (text (ck/eca-compose--text))
        (compose (current-buffer)))
    (unless (buffer-live-p src)
      (user-error "Source ECA chat buffer is gone"))
    (when (and send (string-empty-p text))
      (user-error "Refusing to send an empty prompt"))
    (with-current-buffer src
      (if send
          (eca-chat--send-prompt (eca-session) text)
        (eca-chat--set-prompt text)))
    (when (buffer-live-p compose)
      (kill-buffer compose))
    (when-let* ((win (get-buffer-window src t)))
      (select-window win))))

(defun ck/eca-compose-finish ()
  "Write the composed text back into the source chat prompt without sending."
  (interactive)
  (ck/eca-compose--commit nil))

(defun ck/eca-compose-send ()
  "Write the composed text back into the source chat prompt and send it."
  (interactive)
  (ck/eca-compose--commit t))

(defun ck/eca-compose-abort ()
  "Discard the compose buffer, leaving the chat prompt untouched."
  (interactive)
  (let ((src ck/eca-compose--source-buffer)
        (compose (current-buffer)))
    (when (buffer-live-p compose)
      (kill-buffer compose))
    (when-let* ((win (and (buffer-live-p src) (get-buffer-window src t))))
      (select-window win))))

(defun ck/eca-toggle-compose ()
  "Toggle between the chat prompt and its compose buffer.
In an `eca-chat-mode' buffer this opens the compose buffer; in the
compose buffer it fills the text back into the prompt (without sending).
Bound to `C-c C-c' in both, so one chord flips the edit location either
way."
  (interactive)
  (cond
   ((bound-and-true-p ck/eca-compose-mode) (ck/eca-compose-finish))
   ((derived-mode-p 'eca-chat-mode) (ck/eca-chat-edit-prompt))
   (t (user-error "Not in an ECA chat or compose buffer"))))

(define-key ck/eca-compose-mode-map (kbd "C-c C-c") #'ck/eca-toggle-compose)
(define-key ck/eca-compose-mode-map (kbd "C-c C-s") #'ck/eca-compose-send)
(define-key ck/eca-compose-mode-map (kbd "C-c C-k") #'ck/eca-compose-abort)

;;; Command / skill palette --------------------------------------------------
;;
;; Slash commands and skills are annoying to type out.  Query the server for
;; the exact same catalog its `/' completion uses (native commands, skills,
;; custom prompts, MCP prompts, each with a description) and pick one with
;; `ivy-read', inserting `/<name> ' at point so any arguments can be typed.

(defun ck/eca-chat--all-commands ()
  "Return the ECA server's full command/skill/prompt catalog for this chat.
Each entry is a plist with `:name', `:type', `:description', `:arguments'."
  (let ((session (eca-session)))
    (eca-assert-session-running session)
    (append
     (plist-get (eca-api-request-sync session
                                      :method "chat/queryCommands"
                                      :params (list :chatId eca-chat--id
                                                    :query ""))
                :commands)
     nil)))

(defun ck/eca-chat-insert-command ()
  "Pick an ECA command, skill or prompt via `ivy-read' and insert it.
Lists everything the server exposes for `/' completion, with type and
description, and inserts `/<name> ' at the prompt so you never type the
name out (point is left after the space, ready for any arguments)."
  (interactive)
  (unless (derived-mode-p 'eca-chat-mode)
    (user-error "Not in an ECA chat buffer"))
  (let* ((commands (ck/eca-chat--all-commands))
         (width (apply #'max 1 (mapcar (lambda (c) (length (plist-get c :name)))
                                       commands)))
         (table (mapcar
                 (lambda (c)
                   (cons (format "%-*s  %-13s  %s"
                                 width
                                 (plist-get c :name)
                                 (format "(%s)" (or (plist-get c :type) ""))
                                 (or (plist-get c :description) ""))
                         c))
                 commands)))
    (unless table
      (user-error "No ECA commands available"))
    (ivy-read
     "ECA command: " table
     :require-match t
     :caller 'ck/eca-chat-insert-command
     :action
     (lambda (sel)
       ;; ivy hands the action the selected label string; resolve the plist.
       (let* ((cmd (cdr (assoc (if (consp sel) (car sel) sel) table)))
              (name (plist-get cmd :name)))
         (when name
           (unless (eca-chat--point-at-prompt-field-p)
             (goto-char (point-max)))
           (eca-chat--insert (concat "/" name " "))))))))

;;; Package setup -----------------------------------------------------------

(use-package eca
  ;; init.el restricts `package-load-list', so the package's own autoloads
  ;; never load; stub the entry command ourselves or nothing defines `eca'.
  :commands (eca)
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  (eca-chat-mode . ck/eca--sweep-on-chat-kill)
  :config
  (setq eca-chat-use-side-window nil)

  ;; Window placement for eca chats:
  ;; - re-displaying the current chat reuses its window;
  ;; - a chat whose ECA workspace is already on screen toggles into that
  ;;   window (same-workspace chats share one window);
  ;; - the first chat of a workspace spawns leftmost (full height, from the
  ;;   whole frame); prettify then sizes it to `prettify-width' cols once the
  ;;   layout settles.
  (add-to-list 'display-buffer-alist
               '("\\`<eca-chat"
                 (display-buffer-reuse-window
                  ck/eca-display-reuse-same-workspace-window
                  display-buffer-in-direction)
                 (direction . left)
                 (window . root)
                 (body-function . (lambda (_w) (ck/prettify-windows)))))

  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-preview-latex)
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-align-tables)

  (advice-add 'eca-process-stop :after #'ck/eca--sweep-closed-buffers)
  (advice-add 'eca-chat-exit    :after #'ck/eca--sweep-closed-buffers)
  (advice-add 'eca-config-updated
              :around #'ck/eca--config-updated-attach-chat-id)
  (advice-add 'eca-chat-config-updated
              :around #'ck/eca--config-updated-guard-globals)
  (dolist (fn '(eca-chat--set-agent
                eca-chat-select-model
                eca-chat-select-variant))
    (advice-add fn :around #'ck/eca--shadow-config-globals))

  ;; `C-c C-c' toggles the prompt into (and, from the compose buffer, back
  ;; out of) a dedicated edit buffer -- one chord either direction.  Bound
  ;; outside an evil state so it works whether typing (insert) or navigating
  ;; (normal) in the prompt.
  (define-key eca-chat-mode-map (kbd "C-c C-c") #'ck/eca-toggle-compose)

  (general-def 'normal eca-chat-mode-map
    [remap ck/empty-mode-leader]     #'hydra-eca/body))

(defhydra hydra-eca (:exit t :columns 5)
  "eca-chat-mode"
  ("c" #'eca-chat-clear-prompt "Clear prompt")
  ("p" #'ck/eca-chat-edit-prompt "Edit prompt (compose)")
  ("a" #'eca-chat-select-agent "Select agent")
  ("m" #'eca-chat-select-model "Select the model")
  ("o" #'ck/eca-chat-new-registered "New chat")
  ("t" #'eca-chat-select "Select chat")
  ("e" #'eca-chat-resume "Open server chat")
  ("f" #'ck/eca-chat-insert-command "Insert command/skill")
  ("n" #'eca-chat-rename "Rename chat")
  ("v" #'eca-chat-select-variant "Select the variant")
  ("l" #'tab-line-switch-to-next-tab "Next tab")
  ("h" #'tab-line-switch-to-prev-tab "Prev tab")
  ("k" #'ck/eca-chat-close-tab "Close tab")
  ("K" #'ck/eca-chat-delete-tab "Close tab + delete chat")
  ("L" #'ck/eca-chat-toggle-latex "Toggle LaTeX")
  ("b" #'ck/eca-chat-align-tables "Align tables")
  ("T" #'ck/eca-chat-open-table-wrapped "Open table (wrapped)")
  ("q" #'eca-stop "Stop ECA if running")
  )



(provide 'config/services/eca)
