;; -*- lexical-binding: t; -*-
(require 'prelude) ; `inc' + dash's `->' macro used below (load-time)
(require 'exwm)
(require 'exwm-layout)
(use-package buffer-move)

(defun ck/windows-undedicate-workspace-buffer (dedicated-workspace)
  (interactive
   (list
    (exwm-workspace--prompt-for-workspace
     "Pick dedicated workspace [+/-]: ")))
  (-> dedicated-workspace
    exwm-workspace--workspace-from-frame-or-index
    frame-selected-window
    (set-window-dedicated-p nil)))

(defun ck/windows-fix-broken-workspace (broken-workspace)
  "Place a new frame in the given frame/index, without affecting other frames"
  (interactive
   (list
    (exwm-workspace--prompt-for-workspace
     "Pick broken workspace [+/-]: ")))
  (let* ((current-index exwm-workspace-current-index)
         (default-limit exwm-workspace-switch-create-limit)
         (temp-limit (inc default-limit)))
    (customize-set-variable 'exwm-workspace-switch-create-limit temp-limit)
    (exwm-workspace-switch-create default-limit)
    (exwm-workspace-switch-create current-index)
    (exwm-workspace-swap
     (exwm-workspace--workspace-from-frame-or-index broken-workspace)
     (exwm-workspace--workspace-from-frame-or-index default-limit))
    (customize-set-variable 'exwm-workspace-switch-create-limit default-limit)))

;; `ck/set-window-width' used to live here; it is pure and consumed across
;; areas (text.el, modes/prettify-mode.el), so it moved to lib/utils.el.

;; EXWM manage windows
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
;; Problem
;; -------
;; On a workspace switch EXWM hides off-workspace clients via
;; `exwm-layout--hide', which `xcb:UnmapWindow's the client AND marks it
;; IconicState / _NET_WM_STATE_HIDDEN. For a fullscreen Proton/Wine game that
;; unmap makes its Vulkan WSI surface go "surface-lost / out-of-date".
;;
;; Concrete failure that motivated this (Steam AppID 4597250, Proton
;; Experimental, NVIDIA, DXVK v2.7.1): on surface loss the game's present-timing
;; frame pacing calls `vkGetPastPresentationTimingEXT', whose Proton winevulkan
;; loader thunk asserts `!status' and access-violates (0xc0000005 in
;; winevulkan.so) -> hard crash. Proven from the PROTON_LOG=1 backtrace:
;;   err:msvcrt:_wassert (L"!status && \"vkGetPastPresentationTimingEXT\"",
;;                        L".../winevulkan/loader_thunks.c", 5414)
;; It only happens under EXWM because EXWM genuinely unmaps the window; most
;; stacking WMs keep it mapped-but-hidden, so the surface never dies.
;;
;; The same unmap/iconify is the root of a wider class of EXWM + fullscreen
;; game bugs: black screen on return, the game self-minimizing and not
;; restoring, and resolution/gamma flips on switch.
;;
;; Fix
;; ---
;; For an allowlisted window, DON'T unmap on hide -- just lower it so the
;; opaque active-workspace Emacs frame occludes it (surface stays valid, the
;; game keeps presenting, the present-timing call keeps returning VK_SUCCESS).
;; `exwm-layout--show' re-maps but does NOT restore stack order, so on the way
;; back we must re-raise the window or you return to the frame's black
;; background covering a still-rendering game.
;;
;; Tradeoffs (why this is opt-in per class, not global)
;; ----------------------------------------------------
;; - Kept-mapped games keep rendering in the background (GPU + battery) instead
;;   of idling while iconified.
;; - A game holding an active XGrabKeyboard/XGrabPointer would keep the grab
;;   while you're away (unmap would have released it). None of the listed games
;;   do this; if a future entry strands input, ungrab in the hide advice.
;;
;; To protect another game: add its `exwm-class-name' or `exwm-instance-name'
;; (the buffer name from `exwm-update-class-hook'; Proton games are usually
;; "steam_app_<APPID>") to `ck/exwm-no-unmap-classes'.

(defvar ck/exwm-no-unmap-classes '("steam_app_4597250")
  "EXWM `exwm-class-name'/`exwm-instance-name's to keep mapped on workspace
switch instead of unmapping. Prevents the Vulkan surface-lost crash/black-screen
described above. See the commentary in this file before extending.")

(defun ck/exwm--protected-id-p (id)
  "Non-nil if X window ID belongs to a `ck/exwm-no-unmap-classes' client."
  (when-let ((buf (exwm--id->buffer id)))
    (with-current-buffer buf
      (and (derived-mode-p 'exwm-mode)
           (or (member exwm-class-name    ck/exwm-no-unmap-classes)
               (member exwm-instance-name ck/exwm-no-unmap-classes))))))

(defun ck/exwm-layout--hide-keep-mapped (orig-fn id)
  "Around advice for `exwm-layout--hide'.
For protected windows, lower instead of unmapping so the GPU surface stays
valid; otherwise hide normally."
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
  "After advice for `exwm-layout--show'.
Re-raise protected windows when shown; we lowered (not unmapped) them on hide,
and `exwm-layout--show' does not restore stack order, so without this you return
to the Emacs frame's black background over a still-rendering game."
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
;; Symptom
;; -------
;; Closing certain floating clients (the reproducer is a Bitwarden autofill
;; popup dismissed after a wrong password) killed the whole X session back to
;; the lightdm greeter.  21 of the 24 SIGSEGV WM coredumps over Jan-Jun 2026
;; are this one crash; it is the dominant session-killer, not the rare
;; native-fontify crash (that is a singleton -- see
;; `config/services/eca/crash.el').
;;
;; Root cause (pinned from the PID 8321 gdb backtrace, 2026-06-29)
;; --------------------------------------------------------------
;; `exwm-manage--unmanage-window' (exwm-manage.el) tears a floating client
;; down in two steps: first it fires an X request burst for the floating
;; frame's container -- UnmapWindow / ReparentWindow / DestroyWindow -- and
;; `xcb:flush'es it; then it DEFERS the buffer kill via `exwm--defer 0' (an
;; idle-0 timer).  When that deferred `kill-buffer' runs, the buffer is the
;; sole occupant of the floating child frame's only window, so the kill
;; cascades into an implicit `delete-frame' on that frame.  Deep inside
;; `delete_frame', `Fdelq' (removing the frame from the frame list) hits a
;; QUIT checkpoint -> `process_pending_signals' -> `gobble_input', which reads
;; the STILL-PENDING X destroy burst from the socket -> `handle_one_xevent' ->
;; `gui_consider_frame_title' -> `format_mode_line_unwind_data' on the
;; half-deleted floating frame -> SIGSEGV.  Because Emacs IS the window
;; manager, that abort takes X down with it.
;;
;; This is a reentrancy bug: a non-reentrant structural mutation (frame
;; teardown) is re-entered by X input processing at a QUIT checkpoint while
;; the frame's own destroy events are still in flight.  `inhibit-quit' does
;; NOT help -- `maybe_quit' calls `process_pending_signals' whenever
;; `pending_signals' is set regardless of `inhibit-quit' -- and elisp cannot
;; `block_input'.  The earlier "NVIDIA driver / Xid 8" theory was an
;; unrelated red herring for these 21 crashes (the X log ends cleanly and a
;; fresh Emacs coredump is produced -- a pure Emacs abort).
;;
;; Fix
;; ---
;; Close the race at a SAFE point.  After `exwm-manage--unmanage-window' has
;; flushed the destroy burst but BEFORE its deferred timer fires, force one
;; full X round-trip (a `GetInputFocus' reply).  The server cannot answer the
;; query until it has processed every earlier request, so by the time the
;; reply arrives all the resulting Unmap/Destroy notify events have been read
;; off the socket (and dispatched by xelb, harmlessly -- the ids are already
;; out of `exwm--id-buffer-alist').  The socket is then empty, so when the
;; deferred `kill-buffer' later runs `delete-frame', the QUIT checkpoint finds
;; nothing pending and never reenters `handle_one_xevent' on the dying frame.
;;
;; The round-trip is only done when the window being unmanaged actually had a
;; floating frame (tiled windows never hit this path), and the whole thing is
;; wrapped so a failure here can never itself break window closing: the worst
;; case is falling back to the pre-existing (rare) crash, never a NEW failure
;; mode.  NOTE: `exwm-floating--unset-floating' (float->tile toggle) has the
;; same latent race with its synchronous `delete-frame'; it was never observed
;; crashing, so it is left alone and only noted here.
;;
;; Verification caveat: the crash is intermittent and not reproducible on
;; demand, so this fix cannot be positively proven.  It is deterministic in
;; mechanism, low-risk, and confined to config.  See
;; `.eca/docs/todos.md' (BUG-2) and the decision doc.
;;
;; TEMPORARY monitoring (remove once confident): until the coredump record
;; empirically confirms the fix (weeks with no new `window--delete' SIGSEGV
;; core), each managed-window unmanage logs one crash-surviving line to
;; `~/.cache/cmacs/bug2-test.log' -- timestamp, X id, WM_CLASS class/instance,
;; and whether the advice saw a floating frame; floating closes add the
;; round-trip outcome.  It logs NO window titles, buffer contents, or
;; keystrokes (apps are separate X clients).  Live-verified 2026-07-06: the
;; real Bitwarden popup (`class=firefox inst=Navigator floating=t') drained
;; and the session survived.  Retire this probe (drop `ck/bug2-test-log' and
;; the logging in the advice) when BUG-2 is closed; tracked in `todos.md'.

(defun ck/bug2-test-log (fmt &rest args)
  "Append a timestamped line to the crash-surviving BUG-2 monitor log.
TEMPORARY (see the commentary above): each line is flushed to disk
immediately so it survives a session death.  Errors here are swallowed so
logging can never affect window teardown."
  (ignore-errors
    (let ((line (concat (format-time-string "%F %T.%3N ")
                        (apply #'format fmt args) "\n"))
          (file (expand-file-name "~/.cache/cmacs/bug2-test.log")))
      (make-directory (file-name-directory file) t)
      (let ((coding-system-for-write 'utf-8-unix))
        (write-region line nil file t 'no-message)))))

(defun ck/exwm--unmanage-drain-x (orig-fn id &rest args)
  "Around advice for `exwm-manage--unmanage-window' fixing BUG-2.
When the window being unmanaged had a floating frame, force one X round-trip
after ORIG-FN's destroy burst so the pending X events drain before the
deferred `kill-buffer' runs `delete-frame'.  See the commentary above.
Also logs each invocation + the round-trip outcome via `ck/bug2-test-log'
(TEMPORARY monitoring, remove once BUG-2 is empirically closed)."
  (let* ((buf (exwm--id->buffer id))
         (floating-p (when buf (buffer-local-value 'exwm--floating-frame buf)))
         (cls  (when buf (buffer-local-value 'exwm-class-name buf)))
         (inst (when buf (buffer-local-value 'exwm-instance-name buf))))
    (ck/bug2-test-log "ENTER unmanage id=#x%x class=%s inst=%s floating=%s"
                      id cls inst (and floating-p t))
    (apply orig-fn id args)
    (when (and floating-p
               exwm--connection
               (slot-value exwm--connection 'connected))
      (ck/bug2-test-log "  drain: round-trip start id=#x%x" id)
      (condition-case err
          (progn
            (xcb:+request-unchecked+reply exwm--connection
                (make-instance 'xcb:GetInputFocus))
            (ck/bug2-test-log "  drain: round-trip OK id=#x%x" id))
        (error
         (ck/bug2-test-log "  drain: round-trip ERROR id=#x%x %S" id err)
         (exwm--log "BUG-2 drain round-trip failed: %S" err))))))

(advice-add 'exwm-manage--unmanage-window
            :around #'ck/exwm--unmanage-drain-x)

(provide 'config/desktop/windows)
