
;; set the build order to use!
(setq build-order-file "~/Dropbox/lxndr/wc3/build-orders/_003.edn"
      build-order-steps nil)

(defun run-build-order-step (tm msg)
  (run-at-time
   tm
   nil
   (lambda (msg)
     (shell-command (concat "espeak \"" msg "\"")))
   msg))

(defun alert-build-order ()
  (interactive)
  (setq build-order-steps
        (->> (f-read build-order-file 'utf-8)
          parseedn-read-str
          (--map (run-build-order-step (aref it 0) (aref it 1)))
          (append build-order-steps))))

(defun stop-build-order ()
  (interactive)
  (--each build-order-steps
    (cancel-timer it))
  (setq build-order-steps nil))

;; get f14 working...
(global-exwm-key "<XF86Tools>" #'alert-build-order)
(global-exwm-key "<XF86Launch5>" #'stop-build-order)

(provide 'config/games/wc3)
