(load-theme 'doom-molokai t)
(if (string-equal system-type "gnu/linux")
    (set-default-font "Roboto Mono 6"))
(if (string-equal system-type "darwin")
    (set-default-font "DejaVu Sans Mono 8"))

(provide 'theme-conf)
