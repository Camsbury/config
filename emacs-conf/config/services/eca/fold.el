;; -*- lexical-binding: t; -*-
;;; Fold / expandable-block toggling ----------------------------------------
;;
;; ECA renders tool calls, subagents, and reasoning as expandable blocks.
;; Stock, TAB folds one only from its header line, so a long scrolling block
;; forces you to hunt back up to the top to collapse it.  These commands fold
;; from anywhere:
;;
;;   `ck/eca-chat-tab-dwim'          toggle the block at *or around* point,
;;                                   using ECA's own dwim overlay lookup so a
;;                                   block collapses from inside its content.
;;   `ck/eca-chat-toggle-all-blocks' collapse all when any block is open,
;;                                   else expand all (nested to a fixpoint).
;;
;; Wired to TAB / shift-TAB (and the block navigators to `M-j' / `M-k') in the
;; `eca-chat-mode-map' section of the eca aggregator's `use-package' `:config'.

(require 'prelude)

(declare-functions "eca-chat"
  eca-chat--expandable-content-at-point-dwim
  eca-chat--expandable-content-toggle
  eca-chat--prompt-context-field-ov)

;; markdown-mode buffer-local, set to t by eca-chat-mode.  Declared so the
;; size-gate below can flip it off without a free-variable warning.
(declare-vars markdown-fontify-code-blocks-natively)

(defun ck/eca--block-overlays ()
  "Return every currently-rendered expandable-block label overlay."
  (-filter (lambda (ov) (overlay-get ov 'eca-chat--expandable-content-id))
           (overlays-in (point-min) (point-max))))

;;; Reveal-load size gate ---------------------------------------------------
;;
;; Unfolding a block dumps its whole stored content into the buffer in one
;; shot; with `markdown-fontify-code-blocks-natively' on, font-lock then spins
;; up a real language mode over every fence in that mass, SYNCHRONOUSLY.  On a
;; big tool-result block (measured up to ~400KB here) that stalls redisplay,
;; and since Emacs is the window manager the whole desktop freezes -- the same
;; path can also SIGSEGV the session (see eca/crash.el).  Each block stashes
;; its text off-buffer in its `-segments' / `-ov-content' overlay properties,
;; so we can size a block BEFORE revealing it and, when it is large, turn
;; native code fontify off for the buffer first.  The reveal then renders as
;; fast plain monospace (losing only per-language + native-diff coloring on
;; that chat); normal small blocks are untouched.

(defcustom ck/eca-fold-native-fontify-max-bytes 50000
  "Stored-content byte ceiling for unfolding with native code fontify on.
When a block (single TAB) or a bulk expand (shift-TAB) whose stored text
exceeds this many bytes is about to be revealed, native code-block
fontification is turned off buffer-locally FIRST, so a huge reveal cannot
freeze or crash the WM Emacs.  Blocks here cluster far below this (<2KB)
or far above (>=56KB), so 50KB sits cleanly in the gap.  Raise to allow
bigger colored reveals; lower to be more conservative."
  :type 'integer
  :group 'ck/eca)

(defcustom ck/eca-fold-expand-all-confirm-bytes 500000
  "Total revealed bytes above which shift-TAB expand-all asks first.
Even with native fontify disabled, dumping megabytes of collapsed blocks
into the buffer at once is a multi-second markdown-fontify stall, so a
bulk expand past this size prompts before proceeding."
  :type 'integer
  :group 'ck/eca)

(defun ck/eca--tree-string-bytes (x)
  "Recursively sum the lengths of every string reachable in X.
Handles the segment lists / conses / live overlays that ECA stashes a
block's rendered text in, so the total approximates how much text will be
fontified when the block opens."
  (cond ((stringp x) (length x))
        ((consp x) (+ (ck/eca--tree-string-bytes (car x))
                      (ck/eca--tree-string-bytes (cdr x))))
        ((and (overlayp x) (overlay-buffer x))
         (abs (- (overlay-end x) (overlay-start x))))
        (t 0)))

(defun ck/eca--block-content-bytes (ov)
  "Stored-content byte count for block label overlay OV, without opening it."
  (max (ck/eca--tree-string-bytes
        (overlay-get ov 'eca-chat--expandable-content-segments))
       (ck/eca--tree-string-bytes
        (overlay-get ov 'eca-chat--expandable-content-ov-content))))

(defun ck/eca--block-open-p (ov)
  "Non-nil when block label overlay OV is currently expanded."
  (and (overlay-get ov 'eca-chat--expandable-content-toggle) t))

(defun ck/eca--fold-desensitize (reason)
  "Turn native code-block fontify off in this chat buffer, once, loudly.
REASON is folded into the echo-area notice.  A no-op if already off, so a
buffer stays desensitized after the first big reveal."
  (when (bound-and-true-p markdown-fontify-code-blocks-natively)
    (setq-local markdown-fontify-code-blocks-natively nil)
    (message "eca: native code fontify OFF for this chat (%s)" reason)))

;;;###autoload
(defun ck/eca-chat-tab-dwim ()
  "TAB in an eca chat, folding from inside a block.
Toggle the expandable block at or *around* point, so a block collapses
from anywhere within its content, not only from its header line.
Outside any block keep the stock TAB behavior: context completion in
the prompt, else nothing."
  (interactive)
  (if-let* ((ov (eca-chat--expandable-content-at-point-dwim)))
      (let ((bytes (ck/eca--block-content-bytes ov)))
        ;; About to OPEN a large block -> desensitize before the reveal, so
        ;; the incoming mass fontifies as cheap monospace, not a session
        ;; freeze.  Collapsing (already open) only shrinks the load; skip it.
        (when (and (not (ck/eca--block-open-p ov))
                   (> bytes ck/eca-fold-native-fontify-max-bytes))
          (ck/eca--fold-desensitize (format "%dKB block" (/ bytes 1024))))
        (eca-chat--expandable-content-toggle
         (overlay-get ov 'eca-chat--expandable-content-id)))
    (cond
     ((and (eca-chat--prompt-context-field-ov) (eolp))
      (completion-at-point))
     (t t))))

;;;###autoload
(defun ck/eca-chat-toggle-all-blocks ()
  "Fold or unfold every expandable block in the current chat.
Collapse all when any block is open, otherwise expand all, so shift-TAB
flips the whole conversation between dense and detailed.  Expanding
sweeps to a fixpoint (each id tried once) so nested blocks revealed by
opening their parent open too, without looping on content-less blocks."
  (interactive)
  (if (seq-some (lambda (ov)
                  (overlay-get ov 'eca-chat--expandable-content-toggle))
                (ck/eca--block-overlays))
      ;; Any open -> collapse. Collapsing a parent destroys its children, so a
      ;; single pass over the open blocks suffices.
      (dolist (ov (ck/eca--block-overlays))
        (when (overlay-get ov 'eca-chat--expandable-content-toggle)
          (eca-chat--expandable-content-toggle
           (overlay-get ov 'eca-chat--expandable-content-id) t t)))
    ;; None open -> expand to a fixpoint.  Bulk-revealing every block is the
    ;; worst reveal load in the UI, so gate on the total stored bytes first:
    ;; desensitize the buffer past the per-block ceiling, and confirm before a
    ;; genuinely huge dump (megabytes of collapsed tool output at once).
    (let ((total (apply #'+ (mapcar #'ck/eca--block-content-bytes
                                    (ck/eca--block-overlays)))))
      (when (> total ck/eca-fold-native-fontify-max-bytes)
        (ck/eca--fold-desensitize (format "expand-all %dKB" (/ total 1024))))
      (when (or (<= total ck/eca-fold-expand-all-confirm-bytes)
                (yes-or-no-p
                 (format "Expand ALL blocks (~%dKB revealed) in this chat? "
                         (/ total 1024))))
        ;; Opening a parent renders new child overlays; keep sweeping until
        ;; nothing new opens.  `seen' bounds each id to one attempt so a
        ;; content-less block (which never toggles open) can't spin forever.
        (let ((seen (make-hash-table :test 'equal))
              (changed t))
          (while changed
            (setq changed nil)
            (dolist (ov (ck/eca--block-overlays))
              (let ((id (overlay-get ov 'eca-chat--expandable-content-id)))
                (unless (or (gethash id seen)
                            (overlay-get ov 'eca-chat--expandable-content-toggle))
                  (puthash id t seen)
                  (eca-chat--expandable-content-toggle id t nil)
                  (setq changed t))))))))))

(provide 'config/services/eca/fold)
