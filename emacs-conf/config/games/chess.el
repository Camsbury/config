;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'browse-url)
(require 'core/env)
(require 'config/utils)

(defvar puzzle-themes
  (--> (concat cmacs-share-path "/puzzle-themes.edn")
       (f-read it 'utf-8)
       (parseedn-read-str it)
       (append it nil)))

(defun ck/edit-fen-on-lichess (fen)
  "Edit FEN on lichess.org"
  (interactive "sFEN: ")
  (-> "https://lichess.org/editor?fen="
      (concat (url-hexify-string fen))
      browse-url))

(defun ck/view-fen-on-lichess (fen)
  "View FEN on lichess.org"
  (interactive "sFEN: ")
  (-> "https://lichess.org/analysis/"
    (concat (replace-regexp-in-string " " "_" fen))
      browse-url))

(defun ck/play-puzzle-theme (theme)
  (-> "https://lichess.org/training"
      (concat "/" theme)
      browse-url))

(defun ck/play-random-puzzle-theme ()
  (interactive)
  (-> puzzle-themes
      random-choice
      ck/play-puzzle-theme))

;; TODO: used to include fen, very sad.
;; let's grab them interactively as we need them!
(defun ck/extract-eco-and-detail (line)
  (string-match "\\(.*\t.*\\)\t\\(.*\\)" line)
  (list (match-string 1 line)
        (match-string 2 line)))

(defun ck/extract-openings ()
  "extract openings from website"
  (interactive)
  (->> '("a" "b" "c" "d" "e")
       (-map  (lambda (s)
                (concat
                 "https://raw.githubusercontent.com/lichess-org/chess-openings/master/"
                 s
                 ".tsv")))
       (-map #'url-file-local-copy)
       (-map #'ck/file-to-string)
       (-map (lambda (s) (split-string s "\n" t)))
       (-map #'cdr)
       (-flatten)
       (-map #'ck/extract-eco-and-detail)))

(defun ck/expand-fen (fen)
  "Expand a fen to include blanks explicitly"
  (let ((fen (car (split-string fen " " t)))
        (blank-replacements
         (->> (number-sequence 1 8)
              (-map (lambda (n) (list n (make-string n ?x))))))
        (replace-blank
         (lambda (ac rep)
           (let ((n (number-to-string (car rep)))
                 (xs (cadr rep)))
             (replace-regexp-in-string n xs ac)))))
    (-reduce-from replace-blank fen blank-replacements)))


(defun ck/swap-char-case (s)
  (replace-regexp-in-string
   "[a-zA-Z]"
   (lambda (x)
     (if (s-uppercase? x)
         (s-downcase x)
       (s-upcase x)))
   s
   t))

(defun ck/transpose-expanded-fen (fen)
  (->> (s-split "/" fen t)
    (reverse)
    (s-join "/")
    (ck/swap-char-case)))

(defun ck/--expanded-fen-distance (fen-a fen-b)
  (length
   (-non-nil
    (-zip-with
     (lambda (a b)
       (not (equal a b)))
     (s-split "" fen-a t)
     (s-split "" fen-b t)))))


(defun ck/expanded-fen-distance (fen-a fen-b)
  "fen-distance for expanded FENs"
  (min
   (ck/--expanded-fen-distance fen-a fen-b)
   (ck/--expanded-fen-distance fen-a (ck/transpose-expanded-fen fen-b))))

(defun ck/fen-distance (fen-a fen-b)
  "Calculate how similar one chess position is to another"
  (--fen-distance
   (ck/expand-fen fen-a)
   (ck/expand-fen fen-b)))


(defun ck/ivy-copy-eco-pgn ()
  "copy PGN for ECO opening"
  (interactive)
  (defvar openings (ck/extract-openings))
  (ivy-read
   "Opening: "
   openings
   :action (lambda (x) (kill-new (cadr x)))))


;; (defun ivy-copy-eco-fen ()
;;   "copy FEN for ECO opening"
;;   (interactive)
;;   (defvar openings (extract-openings))
;;   (ivy-read
;;    "Opening: "
;;    openings
;;    :action (lambda (x) (kill-new (caddr x)))))

;; (defun --ivy-similar-position-copy-eco-fen (chosen)
;;   (let* ((min-distance 12)
;;          (chosen (expand-fen (caddr chosen)))
;;          (openings (->> openings
;;                      (-map
;;                       (lambda (opening)
;;                         (list
;;                          (expanded-fen-distance chosen (expand-fen (caddr opening)))
;;                          opening)))
;;                      (-filter (lambda (x) (< (car x) min-distance)))
;;                      (-sort (lambda (a b) (< (car a) (car b))))
;;                      (-map #'cadr))))
;;     (ivy-read
;;      "Opening: "
;;      openings
;;      :action (lambda (x) (kill-new (caddr x))))))

;; (defun ivy-similar-position-copy-eco-fen ()
;;   "Find a similar ECO opening, then copy the FEN"
;;   (interactive)
;;   (defvar openings (extract-openings))
;;   (ivy-read
;;    "Opening: "
;;    openings
;;    :action #'--ivy-similar-position-copy-eco-fen))

;; (defun --ivy-similar-position-copy-eco-pgn (chosen)
;;   (let* ((min-distance 12)
;;          (chosen (expand-fen (caddr chosen)))
;;          (openings (->> openings
;;                      (-map
;;                       (lambda (opening)
;;                         (list
;;                          (expanded-fen-distance chosen (expand-fen (caddr opening)))
;;                          opening)))
;;                      (-filter (lambda (x) (< (car x) min-distance)))
;;                      (-sort (lambda (a b) (< (car a) (car b))))
;;                      (-map #'cadr))))
;;     (ivy-read
;;      "Opening: "
;;      openings
;;      :action (lambda (x) (kill-new (cadr x))))))

;; (defun ivy-similar-position-copy-eco-pgn ()
;;   "Find a similar ECO opening, then copy the PGN"
;;   (interactive)
;;   (defvar openings (extract-openings))
;;   (ivy-read
;;    "Opening: "
;;    openings
;;    :action #'--ivy-similar-position-copy-eco-pgn))

(defun ck/ivy-play-puzzle-theme ()
  "Open a puzzle theme on lichess"
  (interactive)
  (ivy-read
   "Puzzle theme: "
   puzzle-themes
   :action #'ck/play-puzzle-theme))

(defun ck/open-local-blitz-tactics (&optional browse-p)
  "opens a local blitz tactics instance"
  (interactive)
  (when (not (get-buffer "*Blitz Tactics Server*"))
    (let ((display-buffer-alist
           '(("\\*Blitz Tactics Server\\*"
              (display-buffer-no-window)
              t))))
      (async-shell-command
       "cd ~/projects/Camsbury/blitz-tactics && nix-shell --run 'yarn drun'"
       (generate-new-buffer-name "*Blitz Tactics Server*"))))
  (when browse-p
    (ck/open-firefox)
    (browse-url "http://localhost:3000")))

(defun ck/browse-in-order (urls)
  (dolist (url urls)
    (sleep-for 0.01)
    (browse-url url)))

(defun ck/open-chess-practice ()
  "open all the things you need to practice"
  (interactive)
  (ck/open-local-blitz-tactics)
  (ck/open-firefox)
  (ck/browse-in-order
   '("https://chessable.com/"
     "https://chessbook.com/"
     ;; warm up puzzles
     "http://localhost:3000")))


(provide 'config/games/chess)
