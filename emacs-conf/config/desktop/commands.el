;; -*- lexical-binding: t; -*-
(require 'core/env)
(require 'projectile)
(require 'exwm)

(use-package alarm-clock
  :init
  (defun ck/alarm-message-espeak (_title msg)
    (shell-command (concat "espeak-ng \"" msg "\"")))
  :config
  (setq alarm-clock-play-sound nil)
  (setq alarm-clock-system-notify nil)
  (advice-add #'alarm-clock--notify :after #'ck/alarm-message-espeak))

(use-package deadgrep)

;; The shell-command helpers (`ck/-run-shell-command', `rafd--*',
;; `ck/run-async-from-desc', ...) moved to lib/shell.el (library/application
;; seam); consumers require that directly.


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Child modules: hardware/desktop commands, nix tooling, app launchers

(m-require config/desktop/commands
  system
  nix
  launchers)

(provide 'config/desktop/commands)

;; `ck/alarm-message-espeak' is defined in the use-package `:init' above and
;; forward-referenced in `:config'; `alarm-clock--notify' is the deferred
;; package's own fn.  Suppress just the unresolved class.
;; Local Variables:
;; byte-compile-warnings: (not unresolved)
;; End:
