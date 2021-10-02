(require 'prelude)
(require 'exwm)
(require 'exwm-config)

(setq wbo-path  "~/Dropbox/lxndr/wc3/build-orders/"
      wbo-file "builds.edn"
      wbos      (--> (concat wbo-path wbo-file)
                  (f-read it 'utf-8)
                  (parseedn-read-str it)
                  (append it nil)
                  (nconc it it))
      wbo-steps nil)

(defun wbo-cycle ()
  (interactive)
  (setq wbos (cdr wbos))
  (->> wbos
    car
    (gethash :name)
    (concat "Loading ")
    espeak))

(defun wbo-clear (&rest silent)
  (interactive)
  (when (not silent)
    (->> wbos
      car
      (gethash :name)
      (concat "Clearing ")
      espeak))
  (--each wbo-steps
    (cancel-timer it))
  (setq wbo-steps nil))

(defun wbo-initiate ()
  (interactive)
  (wbo-clear t)
  (->> wbos
       car
       (gethash :name)
       (concat "Starting ")
       espeak)
  (setq wbo-steps
        (->> wbos
             car
             (gethash :file)
             (concat wbo-path)
             ((lambda (x) (f-read x 'utf-8)))
             parseedn-read-str
             (--map (run-at-time (aref it 0) nil #'espeak (aref it 1)))
             (append wbo-steps))))

(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch7>") . wbo-initiate)))
(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch5>") . wbo-clear)))
(customize-set-variable 'exwm-input-global-keys
                          (add-to-list
                           'exwm-input-global-keys
                           `(,(kbd "<XF86Launch6>") . wbo-cycle)))

(provide 'config/games/wc3)
