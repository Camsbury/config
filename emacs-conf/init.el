(require 'init-options)
;; set up use-package
(customize-set-variable 'package-load-list
                        '((bind-key t)
                          (use-package t)))
(package-initialize)
(require 'prelude)
(require 'core)
(require 'config)
;; initialize workspaces
(dolist (i (number-sequence 0 9))
  (exwm-workspace-switch-create i))
(exwm-workspace-switch 1)
