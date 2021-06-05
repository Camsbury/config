(require 'config/utils)

(defun view-fen-on-lichess (fen)
  "View FEN on lichess.org"
  (interactive "sFEN: ")
  (-> "https://lichess.org/editor?fen="
      (concat (url-hexify-string fen))
      browse-url))

 (defun extract-eco-and-detail (line)
   (string-match "\\(.*\t.*\\)\t\\(.*\\)\t\\(.*\\)" line)
   (list (match-string 1 line)
         (match-string 2 line)
         (match-string 3 line)))

(defun extract-openings ()
  "extract openings from website"
  (interactive)
  (->> '("a" "b" "c" "d" "e")
       (-map  (lambda (s)
                (concat "https://raw.githubusercontent.com/niklasf/eco/master/"
                        s
                        ".tsv")))
       (-map #'url-file-local-copy)
       (-map #'file-to-string)
       (-map (lambda (s) (split-string s "\n" t)))
       (-map #'cdr)
       (-flatten)
       (-map #'extract-eco-and-detail)))

(defun expand-fen (fen)
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


(defun swap-char-case (s)
  (replace-regexp-in-string
   "[a-zA-Z]"
   (lambda (x)
     (if (s-uppercase? x)
         (s-downcase x)
       (s-upcase x)))
   s
   t))

(defun transpose-expanded-fen (fen)
  (->> (s-split "/" fen t)
    (reverse)
    (s-join "/")
    (swap-char-case)))

(defun --expanded-fen-distance (fen-a fen-b)
  (length
   (-non-nil
    (-zip-with
     (lambda (a b)
       (not (equal a b)))
     (s-split "" fen-a t)
     (s-split "" fen-b t)))))


(defun expanded-fen-distance (fen-a fen-b)
  "fen-distance for expanded FENs"
  (min
   (--expanded-fen-distance fen-a fen-b)
   (--expanded-fen-distance fen-a (transpose-expanded-fen fen-b))))

(defun fen-distance (fen-a fen-b)
  "Calculate how similar one chess position is to another"
  (--fen-distance
   (expand-fen fen-a)
   (expand-fen fen-b)))


(defun ivy-copy-eco-pgn ()
  "copy PGN for ECO opening"
  (interactive)
  (defvar openings (extract-openings))
  (ivy-read
   "Opening: "
   openings
   :action (lambda (x)
             (->
              (concat "echo \"" (caddr x) " *\" | pgn-extract -s")
              (shell-command-to-string)
              (kill-new)))))


(defun ivy-copy-eco-fen ()
  "copy FEN for ECO opening"
  (interactive)
  (defvar openings (extract-openings))
  (ivy-read
   "Opening: "
   openings
   :action (lambda (x) (kill-new (cadr x)))))

(defun --ivy-similar-position-copy-eco-fen (chosen)
  (let* ((min-distance 12)
         (chosen (expand-fen (cadr chosen)))
         (openings (->> openings
                     (-map
                      (lambda (opening)
                        (list
                         (expanded-fen-distance chosen (expand-fen (cadr opening)))
                         opening)))
                     (-filter (lambda (x) (< (car x) min-distance)))
                     (-sort (lambda (a b) (< (car a) (car b))))
                     (-map #'cadr))))
    (ivy-read
     "Opening: "
     openings
     :action (lambda (x) (kill-new (cadr x))))))

(defun ivy-similar-position-copy-eco-fen ()
  "Find a similar ECO opening, then copy the FEN"
  (interactive)
  (defvar openings (extract-openings))
  (ivy-read
   "Opening: "
   openings
   :action #'--ivy-similar-position-copy-eco-fen))

(defun --ivy-similar-position-copy-eco-pgn (chosen)
  (let* ((min-distance 12)
         (chosen (expand-fen (cadr chosen)))
         (openings (->> openings
                     (-map
                      (lambda (opening)
                        (list
                         (expanded-fen-distance chosen (expand-fen (cadr opening)))
                         opening)))
                     (-filter (lambda (x) (< (car x) min-distance)))
                     (-sort (lambda (a b) (< (car a) (car b))))
                     (-map #'cadr))))
    (ivy-read
     "Opening: "
     openings
     :action (lambda (x)
               (->
                   (concat "echo \"" (caddr x) " *\" | pgn-extract -s")
                 (shell-command-to-string)
                 (kill-new))))))

(defun ivy-similar-position-copy-eco-pgn ()
  "Find a similar ECO opening, then copy the PGN"
  (interactive)
  (defvar openings (extract-openings))
  (ivy-read
   "Opening: "
   openings
   :action #'--ivy-similar-position-copy-eco-pgn))

(provide 'config/shah)
