(require 'racket-mode)

(my-mode-leader-def
 :states  'normal
 :keymaps 'racket-mode-map
 "l" 'racket-repl
 "r" 'racket-run-and-switch-to-repl
 "t" 'racket-test)

(provide 'racket-conf)
