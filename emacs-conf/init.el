;; -*- lexical-binding: t; -*-
(setq gc-cons-threshold most-positive-fixnum)
(require 'init-options)
;; set up use-package
(customize-set-variable 'package-load-list
                        '((bind-key t)
                          (use-package t)))
(package-initialize)
(require 'prelude)
(require 'core)
(require 'config)
;; Steady-state GC. Agents (ECA) cons hard via JSON parsing + fontification
;; of streamed output; a small threshold means GC pauses fire *inside*
;; redisplay and stall every workspace frame. 128MB keeps GC out of the hot
;; path. See config/performance.el for the redisplay-side tuning.
(setq gc-cons-threshold (* 128 1024 1024)
      gc-cons-percentage 0.2)

;; initialize workspaces
(dolist (i (number-sequence 0 9))
  (exwm-workspace-switch-create i))
(exwm-workspace-switch 1)
