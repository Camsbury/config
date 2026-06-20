;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'exwm)

(setq wbo-path  (concat cmacs-share-path "/wc3/build-orders/")
      wbo-file "builds.edn"
      wbo-steps nil)

;; NOTE: call this to refresh from `builds.edn'
(defun ck/wbo-get-wbos ()
  (interactive)
  (setq wbos
   (--> (concat wbo-path wbo-file)
        (f-read it 'utf-8)
        (parseedn-read-str it)
        (append it nil)
        (nconc it it))))

(ck/wbo-get-wbos)

(defun ck/wbo-cycle ()
  (interactive)
  (setq wbos (cdr wbos))
  (->> wbos
       car
       (gethash :name)
       (concat "Loading ")
       ck/espeak))

(defun ck/wbo-clear (&rest silent)
  (interactive)
  (when (not silent)
    (->> wbos
      car
      (gethash :name)
      (concat "Clearing ")
      ck/espeak))
  (--each wbo-steps
    (cancel-timer it))
  (setq wbo-steps nil))

(defun ck/wbo-initiate ()
  (interactive)
  (ck/wbo-clear t)
  (->> wbos
       car
       (gethash :name)
       (concat "Starting ")
       ck/espeak)
  (setq wbo-steps
        (->> wbos
             car
             (gethash :file)
             (concat wbo-path)
             ((lambda (x) (f-read x 'utf-8)))
             parseedn-read-str
             (--map (run-at-time (aref it 0) nil #'ck/espeak (aref it 1)))
             (append wbo-steps))))

(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch7>") . ck/wbo-initiate)))
(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch5>") . ck/wbo-clear)))
(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch6>") . ck/wbo-cycle)))

(provide 'config/games/wc3)
