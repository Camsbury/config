;; -*- lexical-binding: t; -*-
;; Warcraft 3 build-order caller: reads timed build steps from EDN under
;; $SHAREPATH and speaks them via espeak on schedule.  The XF86 keys are
;; registered in the EXWM global map so they work inside the fullscreen
;; game (tier wm; NOT part of the WM layer -- decision 0011 ruling).
(require 'prelude)
(require 'exwm)
(require 'core/env)   ; cmacs-share-path (read at load below)

(declare-functions "config/desktop/commands/system" ck/espeak)

(defvar wbo-path (concat cmacs-share-path "/wc3/build-orders/")
  "Directory holding the build-order EDN files.")

(defvar wbo-file "builds.edn"
  "Index file naming the available build orders.")

(defvar wbo-list nil
  "Build orders from `wbo-file', current one first (rotated by
`ck/wbo-cycle').")

(defvar wbo-steps nil
  "Timers for the currently running build order's spoken steps.")

;; NOTE: call this to refresh from `builds.edn'
(defun ck/wbo-get-wbos ()
  "(Re)load the build-order list from `wbo-file'."
  (interactive)
  (setq wbo-list
        (--> (concat wbo-path wbo-file)
             (f-read it 'utf-8)
             (parseedn-read-str it)
             (append it nil))))

(ck/wbo-get-wbos)

(defun ck/wbo-cycle ()
  "Rotate to the next build order and announce it."
  (interactive)
  (setq wbo-list (append (cdr wbo-list) (list (car wbo-list))))
  (->> wbo-list
       car
       (gethash :name)
       (concat "Loading ")
       ck/espeak))

(defun ck/wbo-clear (&rest silent)
  "Cancel the running build order's timers; announce unless SILENT."
  (interactive)
  (when (not silent)
    (->> wbo-list
      car
      (gethash :name)
      (concat "Clearing ")
      ck/espeak))
  (--each wbo-steps
    (cancel-timer it))
  (setq wbo-steps nil))

(defun ck/wbo-initiate ()
  "Start the current build order: schedule each timed step's callout."
  (interactive)
  (ck/wbo-clear t)
  (->> wbo-list
       car
       (gethash :name)
       (concat "Starting ")
       ck/espeak)
  (let ((steps (--> wbo-list
                    car
                    (gethash :file it)
                    (concat wbo-path it)
                    (f-read it 'utf-8)
                    (parseedn-read-str it))))
    (setq wbo-steps
          (--map (run-at-time (aref it 0) nil #'ck/espeak (aref it 1))
                 steps))))

;; Register the build-order keys in the global WM map.  core/desktop sets
;; the base list wholesale earlier in the boot; this append is idempotent
;; (replaces any prior binding for these keys instead of accumulating on
;; live re-eval).
(let ((keys `((,(kbd "<XF86Launch7>") . ck/wbo-initiate)
              (,(kbd "<XF86Launch5>") . ck/wbo-clear)
              (,(kbd "<XF86Launch6>") . ck/wbo-cycle))))
  (customize-set-variable
   'exwm-input-global-keys
   (append (-remove (lambda (pair) (assoc (car pair) keys))
                    exwm-input-global-keys)
           keys)))

(provide 'config/games/wc3)
