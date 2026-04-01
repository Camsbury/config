(require 'prelude)
(require 'core/env)
(require 'config/search)

;; TODO: could assign these individual default volumes too
(defvar ck-audio-sink-names
  '(("alsa_output.usb-QTIL_Audioengine_HD3_ABCDEF0123456789-00.analog-stereo"
     . "speakers")
    ("alsa_output.usb-FiiO_FiiO_USB_DAC_E17K-01.analog-stereo"
     . "headphones"))
  "Alist of node.name to friendly display name.
   Unlisted sinks show their node.name.")

(defun ck--audio-sinks ()
  "Return alist of (display-name . node.name) for all available sinks."
  (let ((nodes (split-string
                (string-trim
                 (shell-command-to-string
                  "pw-dump | jq -r '.[] | select(.type==\"PipeWire:Interface:Node\" and .info.props.\"media.class\"==\"Audio/Sink\") | .info.props.\"node.name\"'"))
                "\n" t)))
    (mapcar (lambda (node)
              (let ((friendly (alist-get node ck-audio-sink-names nil nil #'string=)))
                (cons (or friendly node) node)))
            nodes)))

(defun ck-switch-audio-sink ()
  "Switch default audio sink via wpctl with ivy completion."
  (interactive)
  (let* ((sinks (ck--audio-sinks))
         (choice (ivy-read "Sink: " (mapcar #'car sinks)))
         (node-name (alist-get choice sinks nil nil #'string=))
         (id (string-trim
              (shell-command-to-string
               (format "pw-dump | jq -r '.[] | select(.info.props.\"node.name\"==\"%s\") | .id'" node-name)))))
    (when (string-empty-p id)
      (user-error "Sink %s not found" choice))
    (shell-command (format "wpctl set-default %s" id))
    (shell-command (format "wpctl set-mute %s 0" id))
    (shell-command (format "wpctl set-volume %s 0.7" id))))

(provide 'config/desktop/sound)
