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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Dedicate and undedicate the fullscreen client's own window
;;
;; `exwm-layout-set-fullscreen', `exwm-layout-unset-fullscreen' and
;; `exwm-manage--unmanage-window' find the window to dedicate with
;; `(get-buffer-window)', which searches the selected frame only.  A client
;; that goes fullscreen or exits while another workspace is selected gets
;; nil there, so set-fullscreen dedicates the selected window instead (the
;; buffer you are looking at) and unmanage never clears the client's own
;; window.  `exwm-layout--refresh-workspace' later tries to put another
;; buffer in that window and throws "Window is dedicated", which aborts
;; the refresh and the workspace-switch focus hand-off.

(defun ck/exwm--with-client-window-selected (orig-fn &rest args)
  "Call ORIG-FN with ARGS while the client's window is selected.
The client buffer is `(car ARGS)' as an X id, or the current buffer.  Its
window is looked up on every frame so upstream's frame-local
`get-buffer-window' finds the window it dedicates or undedicates.  The
selection is norecord, so EXWM's focus timer does not fire.  Without a
window ORIG-FN runs unchanged."
  (let* ((id (car args))
         (buf (if id (exwm--id->buffer id) (current-buffer)))
         (window (and buf (get-buffer-window buf t))))
    (if (window-live-p window)
        (with-selected-window window
          (apply orig-fn args))
      (apply orig-fn args))))

(defun ck/exwm--unmanage-with-fullscreen-window (orig-fn id &rest args)
  "Call ORIG-FN on ID and ARGS, selecting ID's window when it is fullscreen.
Only a fullscreen client has a dedicated tiling window to clear, and the
floating teardown path is left untouched."
  (let ((buf (exwm--id->buffer id)))
    (if (and buf (with-current-buffer buf (exwm-layout--fullscreen-p)))
        (apply #'ck/exwm--with-client-window-selected orig-fn id args)
      (apply orig-fn id args))))

(advice-add 'exwm-layout-set-fullscreen
            :around #'ck/exwm--with-client-window-selected)
(advice-add 'exwm-layout-unset-fullscreen
            :around #'ck/exwm--with-client-window-selected)
(advice-add 'exwm-manage--unmanage-window
            :around #'ck/exwm--unmanage-with-fullscreen-window)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Adopt a cross-workspace client before focusing it
;;
;; With `exwm-layout-show-all-buffers' any switch command (consult-buffer,
;; `evil-next-buffer', a mouse click) can show an X client whose
;; `exwm--frame' still names another workspace.  `exwm-input--update-focus'
;; then does not focus the client: it switches to that other workspace.
;; Upstream relies on `exwm-layout--refresh' (a redisplay hook) to move the
;; window here first, but the focus timer can fire before redisplay, and
;; the refresh can throw.  Doing the move at the decision point makes the
;; order irrelevant; the two are idempotent with each other.

(defun ck/exwm--adopt-window-before-focus (window)
  "Move WINDOW's tiling X client to the current workspace before focusing.
Runs before `exwm-input--update-focus'.  Only acts when WINDOW is live, on
the current workspace frame, and shows a tiling `exwm-mode' buffer whose
`exwm--frame' is another workspace.  Floating clients are left alone."
  (when (and (window-live-p window)
             (eq (window-frame window) exwm-workspace--current))
    (with-current-buffer (window-buffer window)
      (when (and (derived-mode-p 'exwm-mode)
                 (not exwm--floating-frame)
                 (not (eq exwm--frame exwm-workspace--current)))
        (exwm--log "Adopting #x%x into %s" exwm--id exwm-workspace--current)
        (exwm-workspace-move-window exwm-workspace--current exwm--id)))))

(advice-add 'exwm-input--update-focus
            :before #'ck/exwm--adopt-window-before-focus)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Floor floating client geometry at its WM_NORMAL_HINTS minimum
;;
;; A new floating client can end up in a frame far narrower than its
;; container.  Observed with Firefox's Bitwarden extension popup (class
;; firefox/Navigator, type DIALOG, min hints 139x139): the Emacs frame
;; shrinks to 141 px (139 + 2 internal border) while the container stays at
;; the original 704 px.
;;
;; Cause: `exwm-floating--set-floating' resizes the new floating frame with
;; a raw X ConfigureWindow and immediately calls `exwm-layout--show', which
;; sizes the client from Emacs's cached window edges.  On that first call
;; the cache still describes the 10x4-column placeholder frame, so the
;; client receives a size below its WM_NORMAL_HINTS minimum.  A GTK client
;; answers with a ConfigureRequest for its minimum, and EXWM's floating
;; ConfigureRequest handler shrinks the Emacs frame to that width.  Upstream
;; marks the gap with "FIXME: check normal hints restrictions" in
;; exwm-floating.el.
;;
;; Fix: wrap `exwm--set-geometry', the one function that sends client
;; geometry to X.  For a floating client, raise each requested dimension to
;; the client's min hint when both are numbers.  The stale first size is
;; then harmless, and the normal `window-size-change-functions' ->
;; `exwm-layout--refresh' path sets the real size afterwards.  Tiled
;; clients, containers, and frame outer windows pass through untouched at
;; the cost of one alist lookup.  A nil dimension means "do not touch", so
;; it stays nil; a value is never lowered.

(defun ck/exwm--floor-floating-geometry (orig-fn xwin x y width height)
  "Call ORIG-FN with WIDTH and HEIGHT floored at XWIN's min size hints.
Only a live floating client is floored.  X and Y pass through.  A nil
WIDTH or HEIGHT stays nil, and a nil hint leaves its dimension unchanged."
  (let ((buf (exwm--id->buffer xwin)))
    (if (not (and buf
                  (buffer-live-p buf)
                  (buffer-local-value 'exwm--floating-frame buf)))
        (funcall orig-fn xwin x y width height)
      (let* ((min-w (buffer-local-value 'exwm--normal-hints-min-width buf))
             (min-h (buffer-local-value 'exwm--normal-hints-min-height buf))
             (new-w (if (and (numberp width) (numberp min-w))
                        (max width min-w)
                      width))
             (new-h (if (and (numberp height) (numberp min-h))
                        (max height min-h)
                      height)))
        (unless (and (eql new-w width) (eql new-h height))
          (exwm--log "Floating #x%x: floored %sx%s to %sx%s (min hints)"
                     xwin width height new-w new-h))
        (funcall orig-fn xwin x y new-w new-h)))))

(advice-add 'exwm--set-geometry :around #'ck/exwm--floor-floating-geometry)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Heal the X request-sequence tally when the server runs ahead
;;
;; X matches replies to requests by position: Emacs counts the requests it
;; sends, the server counts the ones it receives, and each reply carries
;; the low 16 bits of the server's count.  xelb widens that stamp with
;; Emacs's tally and treats a stamp above the tally as a 16-bit wrap,
;; subtracting 65536.  Once the server has counted one request more than
;; Emacs (a send cut short by C-g is one way), every stamp is above the
;; tally, every reply is filed under a negative number, every reply wait
;; hits `xcb:connection-timeout', and no new window can be managed.
;; Upstream has no recovery path; only a restart resets both counts.
;;
;; A real wrap and a desync never look alike: a wrap shows a gap close to
;; 65536, a desync a gap of a few.  On a small gap, trust the server and
;; raise the tally to the stamp.  The one reply in flight at that moment
;; may be delivered to the wrong request (the protocol gives no way to
;; tell); everything after it is matched correctly.

(defconst ck/xcb-sequence-desync-max 32768
  "Largest gap between a stamp and the tally that counts as a desync.
Half the 16-bit range: a real wrap always shows a gap above this.")

(defun ck/xcb--heal-sequence-desync (orig-fn conn sequence16)
  "Call ORIG-FN on CONN and SEQUENCE16, healing a small forward gap.
When SEQUENCE16 is ahead of CONN's tally by less than
`ck/xcb-sequence-desync-max', the server has counted requests Emacs did
not: raise the tally to the stamp and return the stamp.  Otherwise return
ORIG-FN's result, which handles the real 16-bit wrap."
  (let* ((tally (slot-value conn 'request-sequence))
         (stamp (logior (logand tally xcb:-SEQUENCE-SEGMENT-MASK)
                        sequence16))
         (gap (- stamp tally)))
    (if (< 0 gap ck/xcb-sequence-desync-max)
        (progn
          (message
           "cmacs: X sequence desync, server ahead by %d; tally %d -> %d"
           gap tally stamp)
          (setf (slot-value conn 'request-sequence) stamp)
          stamp)
      (funcall orig-fn conn sequence16))))

(advice-add 'xcb:-convert-sequence :around #'ck/xcb--heal-sequence-desync)

(provide 'config/desktop/windows)
