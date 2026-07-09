;; -*- lexical-binding: t; -*-
(require 'core/env)
(require 'projectile)
(require 'exwm)

(use-package alarm-clock
  :init
  (defun ck/alarm-message-espeak (title msg)
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
