;; -*- lexical-binding: t; -*-
;;; Context-bar theme colors -------------------------------------------------
;;
;; The context-usage bar in the eca-chat mode-line colors each segment
;; server-first: eca-emacs prefers a per-category `:color' (and a `:freeColor'
;; for the unused region) that the ECA server pushes as hex strings, and only
;; falls back to the client faces (`eca-chat-context-*-face') for older
;; servers that omit them.  Our pinned server sends colors, so the faces --
;; and thus the doom theme -- never get a say by default.
;;
;; Strip that server color before the four resolvers see it, so each one falls
;; through to its client face.  Those faces are themed from the palette in
;; `config/theme/doom-*.edn' (`:eca-chat-context-*-face'), which is how the
;; bar ends up inheriting the doom colors: the seven category hues from the
;; palette roles, and the free/unused region as `base4'.
;;
;; Rendering quirk worth knowing (drove the EDN choice): in a graphical frame
;; each bar segment is a space whose `:background' is set to the color returned
;; by `eca-chat--context-*-color', and that color is read from the face's
;; FOREGROUND (`face-foreground').  So the free region shows `base4' because
;; the EDN sets `eca-chat-context-free-face' :foreground to base4, even though
;; visually it paints as a background.  Terminal frames draw a `?█' glyph in
;; the face foreground, so the same foreground attribute is correct there too.
;;
;; The advice is installed from the `eca' use-package `:config' in the parent
;; `config/services/eca.el' (where the eca functions are loaded), matching how
;; the sibling advices are wired.  This file only defines the helpers.

(require 'prelude)

(defun ck/eca--plist-delete (plist key)
  "Return a copy of PLIST omitting KEY and its value.
Non-destructive: PLIST is left untouched, so the server breakdown data
is unchanged for every other consumer."
  (let (out)
    (while plist
      (unless (eq (car plist) key)
        (setq out (cons (cadr plist) (cons (car plist) out))))
      (setq plist (cddr plist)))
    (nreverse out)))

(defun ck/eca--strip-cat-color (args)
  "Advice `:filter-args' dropping a context category's server `:color'.
ARGS is the arg list of `eca-chat--context-category-color' /
`...-face-spec' (a single category plist); with `:color' gone both fall
through to the themed `eca-chat-context-*-face'."
  (list (ck/eca--plist-delete (car args) :color)))

(defun ck/eca--strip-free-color (args)
  "Advice `:filter-args' dropping the breakdown's server `:freeColor'.
ARGS is the arg list of `eca-chat--context-free-color' / `...-face-spec'
(a single breakdown plist); with `:freeColor' gone both fall through to
the themed `eca-chat-context-free-face'."
  (list (ck/eca--plist-delete (car args) :freeColor)))

(provide 'config/services/eca/colors)
