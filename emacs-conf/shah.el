(require 'core/utils)

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

(provide 'shah)
