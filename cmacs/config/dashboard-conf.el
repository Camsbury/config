(require 'private-conf)
(require 'json)
(require 'web)

(setq dashboard-tickers
      '(("SPY" . 5)
       ("BTC" . 6)))

;; (defun get-ticker (sym)

;;   sym)

;; (defun get-forex )

(defun fill-ticker (sym)
  (cdr (assoc-string sym dashboard-tickers)))

(comment
 (fill-ticker "SPY"))

(provide 'dashboard-conf)
