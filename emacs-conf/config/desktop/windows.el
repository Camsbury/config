;; -*- lexical-binding: t; -*-
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

(defun ck/set-window-width (window count)
  "Set the selected window's width."
  (when (and (window-combined-p window t)
             (window-right window))
    (ignore-errors
      (adjust-window-trailing-edge
       window
       (- count (window-width))
       t))))

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

(provide 'config/desktop/windows)
