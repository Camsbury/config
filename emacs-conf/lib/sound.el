;; -*- lexical-binding: t; -*-
;; Audio-sink operations over PipeWire (pw-dump/wpctl/jq): pure library, no
;; wiring.  NOT in the m-require boot chain; the `s-s' WM key reaches
;; `ck/switch-audio-sink' through an autoload stub in core/desktop.el, so
;; this loads on first use.
(require 'prelude)
(require 'core/env)

(defvar ck/audio-sink-names
  '(("alsa_output.usb-QTIL_Audioengine_HD3_ABCDEF0123456789-00.analog-stereo"
     . "speakers")
    ("alsa_output.usb-FiiO_FiiO_USB_DAC_E17K-01.analog-stereo"
     . "headphones"))
  "Alist of node.name to friendly display name.
   Unlisted sinks show their node.name.")

(defun ck/audio-sinks ()
  "Return alist of (display-name . node.name) for all available sinks."
  (let ((nodes (split-string
                (string-trim
                 (shell-command-to-string
                  "pw-dump | jq -r '.[] | select(.type==\"PipeWire:Interface:Node\" and .info.props.\"media.class\"==\"Audio/Sink\") | .info.props.\"node.name\"'"))
                "\n" t)))
    (mapcar (lambda (node)
              (let ((friendly (alist-get node ck/audio-sink-names nil nil #'string=)))
                (cons (or friendly node) node)))
            nodes)))

(defun ck/switch-audio-sink ()
  "Pick a sink by friendly name, make it the default, and unmute it.
Volume is left alone: WirePlumber restores the level it last saw on
that sink (its default-routes state), and each device has its own
comfortable range, so one shared level is wrong for all of them."
  (interactive)
  (let* ((sinks (ck/audio-sinks))
         (choice (completing-read "Sink: " (mapcar #'car sinks) nil t))
         (node-name (alist-get choice sinks nil nil #'string=))
         (id (string-trim
              (shell-command-to-string
               (format "pw-dump | jq -r '.[] | select(.info.props.\"node.name\"==\"%s\") | .id'" node-name)))))
    (when (string-empty-p id)
      (user-error "Sink %s not found" choice))
    (shell-command (format "wpctl set-default %s" id))
    (shell-command (format "wpctl set-mute %s 0" id))))

(defun ck/mpris-players ()
  "Return an alist of (display . instance) for every MPRIS player.
Display is \"name  status  artist - title\"; instance is the
`playerctl -p' target.  One `playerctl -a metadata' call feeds both."
  (let ((lines (split-string
                (shell-command-to-string
                 (concat "playerctl -a metadata --format "
                         "'{{playerInstance}}\t{{playerName}}"
                         "\t{{status}}\t{{artist}} - {{title}}'"))
                "\n" t)))
    (mapcar (lambda (line)
              (pcase-let ((`(,instance ,name ,status ,track)
                           (split-string line "\t")))
                (cons (format "%-10s %-8s %s" name status track)
                      instance)))
            lines)))

(defun ck/play-pause-player ()
  "Pick an MPRIS player with completion and toggle its play/pause.
One-shot: the hardware play key keeps following playerctld's
last-active player; this is the fallback when that player is not
the one you want."
  (interactive)
  (let ((players (ck/mpris-players)))
    (unless players
      (user-error "No MPRIS players running"))
    (let* ((choice (completing-read "Play/pause: " (mapcar #'car players)
                                    nil t))
           (instance (alist-get choice players nil nil #'string=)))
      (shell-command (format "playerctl -p %s play-pause"
                             (shell-quote-argument instance))))))

(provide 'lib/sound)
