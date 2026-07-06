;; -*- lexical-binding: t; -*-
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
;;
;; Rendering is ASYNC.  Emacs is the EXWM window manager, so a synchronous
;; `call-process' to latex/dvisvgm (~300-800ms per uncached fragment) freezes
;; the whole desktop, and `while-no-input' cannot save us: when an X app is
;; focused the command loop never runs, so there is no input event to abort
;; on.  Instead each render runs as a `make-process' chain (latex -> image)
;; behind a bounded queue.  On a cache miss we drop a PLACEHOLDER overlay
;; immediately (raw text stays visible, region is reserved, re-enqueue is
;; blocked) and swap in the image from the process sentinel when it is ready.
;; Cache hits are cheap and rendered inline on the spot.

(require 'prelude)
(require 'color)

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

(defcustom ck/eca-chat-latex-max-jobs 3
  "Maximum number of concurrent async LaTeX render chains.
Each chain spawns latex then dvisvgm/dvipng; the queue holds the rest."
  :type 'integer
  :group 'ck/eca)

(defcustom ck/eca-chat-auto-latex t
  "When non-nil, render LaTeX automatically after each ECA response finishes."
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

(defun ck/eca-chat--latex-paths (fragment rgb)
  "Return a plist of render paths for FRAGMENT colored RGB.
Keys: :key (content hash), :fmt, :tex, :dvi, :out.  The hash formula matches
the historical one so the on-disk cache stays valid across this rewrite."
  (let* ((dir ck/eca-chat-latex-image-dir)
         (dpi ck/eca-chat-latex-dpi)
         (fmt (ck/eca-chat--effective-format))
         (key (secure-hash 'sha1 (format "%s|%S|%d|%s" fragment rgb dpi fmt))))
    (list :key key :fmt fmt
          :tex (expand-file-name (concat key ".tex") dir)
          :dvi (expand-file-name (concat key ".dvi") dir)
          :out (expand-file-name (concat key "." (symbol-name fmt)) dir))))

;;; Async render queue ------------------------------------------------------
;;
;; A job is a plist: (:buffer :overlay :frag :rgb :key :fmt :tex :dvi :out).
;; `--latex-pump' starts jobs up to `ck/eca-chat-latex-max-jobs'; each job
;; runs latex then the image backend as chained `make-process' calls, and
;; `--latex-finish' swaps the placeholder overlay for the image (or drops it
;; on failure), then pumps the next job.

(defvar ck/eca-chat--latex-queue nil
  "List of pending async LaTeX render jobs (plists).")

(defvar ck/eca-chat--latex-running 0
  "Number of in-flight async LaTeX render chains.")

(defun ck/eca-chat--make-latex-overlay (beg end frag &optional img)
  "Create a LaTeX preview overlay over BEG..END for FRAG.
With IMG (an image object) the fragment shows as the image immediately.
Without IMG the overlay is a placeholder: it reserves the region (raw text
stays visible) and blocks re-enqueue until its async render finishes."
  (let ((ov (make-overlay beg end)))
    (overlay-put ov 'ck/eca-latex t)
    (overlay-put ov 'evaporate t)
    (overlay-put ov 'help-echo frag)
    (when img (overlay-put ov 'display img))
    ov))

(defun ck/eca-chat--latex-finish (job ok)
  "Complete JOB: install the image when OK, else drop the placeholder.
Always cleans intermediates, decrements the running count, and pumps."
  (let ((ov (plist-get job :overlay))
        (out (plist-get job :out))
        (key (plist-get job :key))
        (dir ck/eca-chat-latex-image-dir))
    (dolist (ext '(".tex" ".dvi" ".aux" ".log"))
      (ignore-errors (delete-file (expand-file-name (concat key ext) dir))))
    (if (and ok ov (overlay-buffer ov) (file-exists-p out))
        (overlay-put ov 'display (create-image out nil nil :ascent 'center))
      ;; Render failed or the overlay is gone: drop the placeholder so the
      ;; raw text shows again and the fragment can be retried later.
      (when (and ov (overlay-buffer ov)) (delete-overlay ov)))
    (setq ck/eca-chat--latex-running (max 0 (1- ck/eca-chat--latex-running)))
    (ck/eca-chat--latex-pump)))

(defun ck/eca-chat--latex-start-dvi (job)
  "Second stage of JOB: rasterize/vectorize the DVI into the output image."
  (let ((dir ck/eca-chat-latex-image-dir)
        (dpi ck/eca-chat-latex-dpi)
        (dvi (plist-get job :dvi))
        (out (plist-get job :out))
        (fmt (plist-get job :fmt)))
    (condition-case nil
        (make-process
         :name "eca-latex-img"
         :noquery t
         :connection-type 'pipe
         :buffer nil
         :command
         (pcase fmt
           ('svg (list "dvisvgm" "--no-fonts" "--exact" "--bbox=min"
                       "-o" out dvi))
           (_    (list "dvipng" "-D" (number-to-string dpi)
                       "-T" "tight" "-bg" "Transparent" "-o" out dvi)))
         :sentinel
         (lambda (proc _event)
           (when (memq (process-status proc) '(exit signal))
             (ck/eca-chat--latex-finish
              job (and (eq (process-status proc) 'exit)
                       (zerop (process-exit-status proc))
                       (file-exists-p out))))))
      (error (ck/eca-chat--latex-finish job nil)))))

(defun ck/eca-chat--latex-start (job)
  "First stage of JOB: write the .tex and compile it to DVI asynchronously."
  (let ((tex (plist-get job :tex))
        (dir ck/eca-chat-latex-image-dir))
    (condition-case nil
        (progn
          (with-temp-file tex
            (insert (ck/eca-chat--latex-document
                     (plist-get job :frag) (plist-get job :rgb))))
          (make-process
           :name "eca-latex"
           :noquery t
           :connection-type 'pipe
           :buffer nil
           :command (list "latex" "-interaction=nonstopmode" "-halt-on-error"
                          "-output-directory" dir tex)
           :sentinel
           (lambda (proc _event)
             (when (memq (process-status proc) '(exit signal))
               (if (and (eq (process-status proc) 'exit)
                        (zerop (process-exit-status proc)))
                   (ck/eca-chat--latex-start-dvi job)
                 (ck/eca-chat--latex-finish job nil))))))
      (error (ck/eca-chat--latex-finish job nil)))))

(defun ck/eca-chat--latex-pump ()
  "Start queued render jobs until the concurrency limit is reached."
  (while (and ck/eca-chat--latex-queue
              (< ck/eca-chat--latex-running ck/eca-chat-latex-max-jobs))
    (let ((job (pop ck/eca-chat--latex-queue)))
      (setq ck/eca-chat--latex-running (1+ ck/eca-chat--latex-running))
      (ck/eca-chat--latex-start job))))

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
  "Preview the fragment between MBEG and MEND in color RGB, unless skippable.
Cache hits render inline immediately; misses drop a placeholder overlay and
enqueue an async render that fills the image in when it is ready."
  (unless (or (ck/eca-chat--in-code-p mbeg)
              (ck/eca-chat--latex-overlays mbeg mend))
    (let* ((frag (buffer-substring-no-properties mbeg mend))
           (paths (ck/eca-chat--latex-paths frag rgb))
           (out (plist-get paths :out)))
      (if (file-exists-p out)
          (ck/eca-chat--make-latex-overlay
           mbeg mend frag (create-image out nil nil :ascent 'center))
        (let ((ov (ck/eca-chat--make-latex-overlay mbeg mend frag)))
          (push (append (list :buffer (current-buffer) :overlay ov
                              :frag frag :rgb rgb)
                        paths)
                ck/eca-chat--latex-queue)
          (ck/eca-chat--latex-pump))))))

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
Fragments inside markdown code are left as text.  Rendering is async: the
scan returns immediately and images appear as their subprocesses finish."
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
  "Remove LaTeX preview images from the current ECA chat buffer.
In-flight renders whose placeholders are deleted here simply drop their
result when they finish (the sentinel checks the overlay is still live)."
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

(provide 'config/services/eca/latex)
