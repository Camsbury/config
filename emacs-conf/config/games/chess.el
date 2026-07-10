;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'browse-url)
(require 'core/env)
(require 'lib/utils)

(declare-functions "config/desktop/commands/launchers" ck/open-firefox)

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

;; The lichess TSVs carry only eco/name/pgn (they used to include FEN);
;; `ck/openings-add-fens' derives each line's final FEN locally via
;; pgn-extract, so the FEN commands below work again.
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
  ;; was `--fen-distance', a function that never existed under that name
  ;; (latent void-function error; caught by the byte-compile sweep)
  (ck/expanded-fen-distance
   (ck/expand-fen fen-a)
   (ck/expand-fen fen-b)))


(defun ck/copy-eco-pgn ()
  "copy PGN for ECO opening"
  (interactive)
  (let* ((openings (ck/extract-openings))
         (choice (completing-read "Opening: " openings nil t)))
    (kill-new (cadr (assoc choice openings)))))

(defun ck/openings-add-fens (openings)
  "Augment OPENINGS rows (LABEL PGN) to (LABEL PGN FEN).
One `pgn-extract -F' run (system package) derives every line's final
FEN; games come back in input order, and a count mismatch errors rather
than silently misaligning rows."
  (let ((pgn-file (make-temp-file "cmacs-openings" nil ".pgn")))
    (unwind-protect
        (progn
          (with-temp-file pgn-file
            (dolist (o openings)
              (insert (cadr o) " *\n\n")))
          (let ((out (shell-command-to-string
                      (concat "pgn-extract -F --quiet "
                              (shell-quote-argument pgn-file)
                              " 2>/dev/null")))
                (fens '())
                (start 0))
            (while (string-match "{ \"\\([^\"]+\\)\" }" out start)
              (push (match-string 1 out) fens)
              (setq start (match-end 0)))
            (setq fens (nreverse fens))
            (unless (= (length fens) (length openings))
              (user-error "pgn-extract FEN mismatch: %d openings, %d FENs"
                          (length openings) (length fens)))
            (-zip-with (lambda (o fen) (append o (list fen)))
                       openings fens)))
      (delete-file pgn-file))))

(defun ck/copy-eco-fen ()
  "copy FEN for ECO opening"
  (interactive)
  (let* ((openings (ck/openings-add-fens (ck/extract-openings)))
         (choice (completing-read "Opening: " openings nil t)))
    (kill-new (caddr (assoc choice openings)))))

(defun ck/similar-openings (opening openings &optional max-distance)
  "Rows of OPENINGS whose final position is near OPENING's, nearest first.
Compares expanded piece placement via `ck/expanded-fen-distance', keeps
rows under MAX-DISTANCE (default 12), and excludes OPENING itself.
Rows must carry FENs (see `ck/openings-add-fens')."
  (let ((target (ck/expand-fen (caddr opening)))
        (max-distance (or max-distance 12)))
    (->> openings
         (-remove (lambda (o) (equal (car o) (car opening))))
         (-map (lambda (o)
                 (cons (ck/expanded-fen-distance
                        target (ck/expand-fen (caddr o)))
                       o)))
         (-filter (lambda (x) (< (car x) max-distance)))
         (-sort (lambda (a b) (< (car a) (car b))))
         (-map #'cdr))))

(defun ck/similar-position--pick ()
  "Pick an opening, then one whose final position is similar; return its row.
The second read keeps nearest-first order (`ck/completing-read-in-order')."
  (let* ((openings (ck/openings-add-fens (ck/extract-openings)))
         (chosen (assoc (completing-read "Opening: " openings nil t)
                        openings))
         (similar (ck/similar-openings chosen openings)))
    (unless similar
      (user-error "No openings with a position similar to %s" (car chosen)))
    (assoc (ck/completing-read-in-order
            "Similar opening (nearest first): " similar nil t)
           similar)))

(defun ck/similar-position-copy-eco-fen ()
  "Find a similar ECO opening, then copy the FEN"
  (interactive)
  (kill-new (caddr (ck/similar-position--pick))))

(defun ck/similar-position-copy-eco-pgn ()
  "Find a similar ECO opening, then copy the PGN"
  (interactive)
  (kill-new (cadr (ck/similar-position--pick))))

(defun ck/choose-puzzle-theme ()
  "Open a puzzle theme on lichess"
  (interactive)
  (ck/play-puzzle-theme
   (completing-read "Puzzle theme: " puzzle-themes nil t)))

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
