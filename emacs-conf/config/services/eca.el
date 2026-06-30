;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/bindings)
(require 'color)

;; Functions/vars the `eca' package provides at runtime; forward-declared so
;; byte-compiling the helpers below stays warning-free without force-loading eca.
(declare-function eca-table-align "eca-table")
(declare-function eca-table-beautify "eca-table")
(declare-function eca-table-open "eca-table")
(declare-function eca-chat--prompt-area-start-point "eca-chat")
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

;;; Package setup -----------------------------------------------------------

(use-package eca
  :hook
  (eca-chat-mode . (lambda () (whitespace-mode -1)))
  :config
  (setq eca-chat-use-side-window nil)

  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-preview-latex)
  (add-hook 'eca-chat-finished-hook #'ck/eca-chat--auto-align-tables)

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
  ("T" #'eca-table-open "Open table at point"))



(provide 'config/services/eca)
