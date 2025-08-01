(require 'ediff-wind)

(setq ediff-floating-control-frame nil
      ediff-split-window-function #'split-window-horizontally)

(with-eval-after-load 'ediff-wind
  (setq ediff-control-frame-parameters
        (cons '(unsplittable . t) ediff-control-frame-parameters)))

(provide 'config/dev/ediff)
