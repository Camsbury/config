;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'exwm)
(require 'exwm-layout)
(use-package buffer-move)

(setq exwm-manage-configurations '((t managed t)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; hooks

(defvar after-delete-window-hook nil
  "Functions run after a window is deleted")
(defun ck/run-after-delete-window-hook (&rest _)
  (run-hooks 'after-delete-window-hook))
(advice-add #'delete-window :after #'ck/run-after-delete-window-hook)

(defvar after-split-window-hook nil
  "Functions run after a window is split")
(defun ck/run-after-split-window-hook (&rest _)
  (run-hooks 'after-split-window-hook))
(advice-add #'split-window :after #'ck/run-after-split-window-hook)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Keep certain X windows mapped across workspace switches
;;
;; On a workspace switch EXWM hides off-workspace clients via
;; `exwm-layout--hide', which unmaps the client AND marks it IconicState /
;; _NET_WM_STATE_HIDDEN.  For a fullscreen Proton/Wine game that unmap makes
;; its Vulkan WSI surface go "surface-lost", which hard-crashes the game and
;; is also the root of a wider class of EXWM + fullscreen game bugs (black
;; screen on return, self-minimizing, resolution flips).  It only happens
;; under EXWM: most stacking WMs keep the window mapped-but-hidden, so the
;; surface never dies.
;;
;; For an allowlisted window, DON'T unmap on hide: just lower it so the opaque
;; active-workspace Emacs frame occludes it and the surface stays valid.
;; `exwm-layout--show' re-maps but does NOT restore stack order, so on the way
;; back we must re-raise the window or you return to the frame's black
;; background covering a still-rendering game.
;;
;; This is opt-in per class, not global.  A kept-mapped game keeps rendering
;; in the background instead of idling while iconified.  And a
;; game holding an active XGrabKeyboard/XGrabPointer would keep the grab while
;; you are away; if a future entry strands input, ungrab in the hide advice.
;;
;; To protect another game: add its `exwm-class-name' or `exwm-instance-name'
;; to `ck/exwm-no-unmap-classes'. Read the string off the RUNNING client, never
;; guess it from the Steam AppID:
;;
;;   emacsclient --eval '(mapcar (lambda (p) (with-current-buffer (cdr p)
;;     (list (buffer-name) exwm-class-name exwm-instance-name)))
;;     exwm--id-buffer-alist)'
;;
;; The class depends on how the game is built and launched, not on the game.
;; A Proton/Wine title reports "steam_app_<APPID>"; the same title shipped as a
;; native Linux build reports its own name.  So a game can silently fall out of
;; this list when it switches to a native build, and the unmap symptoms come
;; back.  Match on the class, not the instance, when the instance names an
;; engine ("Godot_Engine", "Unity") shared by other apps.

(defvar ck/exwm-no-unmap-classes
  '("steam_app_4597250"                 ; Order of the Sinking Star Demo (Proton)
    "Slay the Spire 2")                 ; native Godot build
  "EXWM `exwm-class-name'/`exwm-instance-name's to keep mapped on workspace
switch instead of unmapping. Prevents the Vulkan surface-lost crash/black-screen
described above. See the commentary in this file before extending.")

(defun ck/exwm--protected-id-p (id)
  "Non-nil if X window ID belongs to a `ck/exwm-no-unmap-classes' client."
  (when-let* ((buf (exwm--id->buffer id)))
    (with-current-buffer buf
      (and (derived-mode-p 'exwm-mode)
           (or (member exwm-class-name    ck/exwm-no-unmap-classes)
               (member exwm-instance-name ck/exwm-no-unmap-classes))))))

(defun ck/exwm-layout--hide-keep-mapped (orig-fn id)
  "Lower a protected window instead of unmapping it, keeping its surface valid.
ORIG-FN is `exwm-layout--hide', which hides any other window ID normally."
  (if (ck/exwm--protected-id-p id)
      (progn
        (exwm--log "Protected #x%x: lowering, NOT unmapping" id)
        (xcb:+request exwm--connection
            (make-instance 'xcb:ConfigureWindow
                           :window id
                           :value-mask xcb:ConfigWindow:StackMode
                           :stack-mode xcb:StackMode:Below))
        (xcb:flush exwm--connection))
    (funcall orig-fn id)))

(defun ck/exwm-layout--show-raise-protected (id &optional _window &rest _)
  "Re-raise a protected window when it is shown.
We lowered rather than unmapped it on hide, and `exwm-layout--show' does not
restore stack order, so without this you return to the Emacs frame's black
background over a still-rendering game."
  (when (ck/exwm--protected-id-p id)
    (xcb:+request exwm--connection
        (make-instance 'xcb:ConfigureWindow
                       :window id
                       :value-mask xcb:ConfigWindow:StackMode
                       :stack-mode xcb:StackMode:Above))
    (xcb:flush exwm--connection)))

(advice-add 'exwm-layout--hide :around #'ck/exwm-layout--hide-keep-mapped)
(advice-add 'exwm-layout--show :after  #'ck/exwm-layout--show-raise-protected)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BUG-2: session death when closing a managed FLOATING window
;;
;; Closing a floating client killed the whole X session back to the greeter.
;; Because Emacs IS the window manager, the abort takes X down with it.
;;
;; Cause: `exwm-manage--unmanage-window' tears a floating client down in two
;; steps.  First it flushes an X request burst for the floating frame's
;; container, then it DEFERS the buffer kill to an idle-0 timer.  That deferred
;; `kill-buffer' cascades into `delete-frame' on the floating child frame, and
;; deep inside it `Fdelq' hits a QUIT checkpoint that runs
;; `process_pending_signals' and reads the STILL-PENDING destroy burst, so X
;; input processing reenters the half-deleted frame and segfaults.
;;
;; This is a reentrancy bug: a non-reentrant frame teardown is re-entered by X
;; input processing while the frame's own destroy events are still in flight.
;; `inhibit-quit' does NOT help: `maybe_quit' processes pending signals
;; regardless, and elisp cannot `block_input'.
;;
;; Fix: after `exwm-manage--unmanage-window' has flushed the destroy burst but
;; BEFORE its deferred timer fires, force one full X round-trip (a
;; `GetInputFocus' reply).  The server cannot answer until it has processed
;; every earlier request, so by the time the reply arrives the resulting
;; notify events have been read off the socket.  The QUIT checkpoint in the
;; later `delete-frame' then finds nothing pending.
;;
;; The round-trip is only done when the window had a floating frame (tiled
;; windows never hit this path), and it is wrapped so a failure here falls back
;; to the pre-existing crash rather than a NEW failure mode.

(defun ck/exwm--unmanage-drain-x (orig-fn id &rest args)
  "Call ORIG-FN on ID and ARGS, then force one X round-trip.
The round-trip only happens when ID had a floating frame.  Draining the
pending X events before the deferred `kill-buffer' runs `delete-frame'
closes the BUG-2 crash race described in the commentary above."
  (let* ((buf (exwm--id->buffer id))
         (floating-p (when buf (buffer-local-value 'exwm--floating-frame buf))))
    (apply orig-fn id args)
    (when (and floating-p
               exwm--connection
               (slot-value exwm--connection 'connected))
      (condition-case err
          ;; The reply is discarded on purpose, and `ignore' says so to the
          ;; byte compiler: without it the macro warns about the unused
          ;; `car' of the reply.
          (ignore
           (xcb:+request-unchecked+reply exwm--connection
               (make-instance 'xcb:GetInputFocus)))
        (error
         (exwm--log "BUG-2 drain round-trip failed: %S" err))))))

(advice-add 'exwm-manage--unmanage-window
            :around #'ck/exwm--unmanage-drain-x)

(provide 'config/desktop/windows)
