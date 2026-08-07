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
;; Strip that server color before the resolvers see it, so each one falls
;; through to its client face.  Those faces are themed from the palette in
;; `config/theme/doom-*.edn' (`:eca-chat-context-*-face'), which is how the
;; bar ends up inheriting the doom colors: the seven category hues from the
;; palette roles, and the free/unused region as `base4'.
;;
;; Rendering quirk worth knowing (drove the EDN choice): in a graphical frame
;; each bar segment is a space whose `:background' is set to the color the
;; resolver returns, and that color is read from the face's FOREGROUND
;; (`face-foreground').  So the free region shows `base4' because the EDN sets
;; `eca-chat-context-free-face' :foreground to base4, even though visually it
;; paints as a background.  Terminal frames draw a `?█' glyph in the face
;; foreground, so the same foreground attribute is correct there too.
;;
;; The strip filters install through the adapter's context color/help
;; extension points, self-registered at the bottom of this file (the adapter
;; owns the underlying `:filter-args' advice).

(require 'prelude)
(require 'config/services/eca/upstream)

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
  "Adapter category-color filter dropping a context category's server `:color'.
ARGS is the arg list the category color/face-spec resolvers receive (a single
category plist); with `:color' gone both fall through to the themed
`eca-chat-context-*-face'."
  (list (ck/eca--plist-delete (car args) :color)))

(defun ck/eca--strip-free-color (args)
  "Adapter free-color filter dropping the breakdown's server `:freeColor'.
ARGS is the arg list the free color/face-spec resolvers receive (a single
breakdown plist); with `:freeColor' gone both fall through to the themed
`eca-chat-context-free-face'."
  (list (ck/eca--plist-delete (car args) :freeColor)))

;;; Tooltip swatch colors ----------------------------------------------------
;;
;; The hover legend prefixes each category with a swatch that PREFERS the
;; server-sent `:emoji' (and `:freeEmoji' for the free region), only falling
;; back to a `█' block drawn in the themed `eca-chat-context-*-face-spec' when
;; the emoji is absent.  Since our server sends emoji, the tooltip painted the
;; server's fixed emoji palette while the bar segments -- with `:color'
;; stripped above -- painted the doom theme, so the two disagreed.  Strip the
;; emoji here too and the swatch takes the block fallback, whose face-spec is
;; the same doom color the matching bar segment uses.

(defun ck/eca--strip-help-emoji (args)
  "Adapter bar-help filter dropping server emoji swatches from the tooltip.
ARGS is the arg list the context-bar hover legend receives (BREAKDOWN USED
FREE LIMIT &optional COMPACT-PCT).  Returns a copy with each category's
`:emoji' and the breakdown's `:freeEmoji' removed so the legend swatches
fall back to the themed `█' block, matching the bar's doom colors.
Non-destructive: the server breakdown is left intact for other consumers."
  (let* ((breakdown (car args))
         (cats (mapcar (lambda (cat) (ck/eca--plist-delete cat :emoji))
                       (append (plist-get breakdown :categories) nil)))
         (breakdown (plist-put (ck/eca--plist-delete breakdown :freeEmoji)
                               :categories cats)))
    (cons breakdown (cdr args))))

;; Self-register the three strippers at load time through the adapter.
(ck/eca-upstream-set-context-category-color-filter #'ck/eca--strip-cat-color)
(ck/eca-upstream-set-context-free-color-filter #'ck/eca--strip-free-color)
(ck/eca-upstream-set-context-bar-help-filter #'ck/eca--strip-help-emoji)

(provide 'config/services/eca/colors)
