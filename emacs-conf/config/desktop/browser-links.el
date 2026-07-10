;; -*- lexical-binding: t; -*-
;; Tagged browser bookmarks, stored by the manage_browser_links.clj Babashka
;; script.  `s-d' on a Firefox window captures the current URL (faked
;; C-l/C-c through EXWM + clipboard); the hydra picks links back out,
;; filtered by an interactively narrowed tag set.
(require 'prelude)
(require 'core/definers)
(require 'browse-url)
(require 'lib/utils)

(declare-functions "config/desktop/commands/launchers" ck/open-firefox)
(declare-functions "exwm-input" exwm-input--fake-key)
(declare-vars exwm-mode-map)


(defvar exwm-browser-set-link-script
  "~/projects/Camsbury/config/manage_browser_links.clj")

(defun exwm-browser-link--bb (&rest args)
  "Run the link-management script with ARGS (each shell-quoted); return
stdout."
  (shell-command-to-string
   (s-join " " (append (list "bb" "-f"
                             (shell-quote-argument
                              (expand-file-name exwm-browser-set-link-script)))
                       (-map #'shell-quote-argument args)))))

(defun exwm-browser-link--get-tags (selected)
  "Tags co-occurring with the SELECTED tag set (all tags when nil)."
  (parseedn-read-str
   (exwm-browser-link--bb "list-tags" (s-join " " selected))))

(defun exwm-browser-link-visit ()
  "Select a link to visit in the browser"
  (interactive)
  (let* ((links (parseedn-read-str (exwm-browser-link--bb "list-all")))
         (n (completing-read "Link: " links nil t)))
    (ck/open-firefox)
    (->> links (gethash n) (gethash :url) browse-url)))

(defun exwm-browser-link--read-tags (&optional narrow)
  "Read tags until DONE; return the selection (newest first).
DONE leads the candidate list (order preserved), so it starts
preselected and a bare RET finishes the set (the old ivy :preselect
behavior).  With NARROW, each pick restricts the next offers to tags
co-occurring with the selection so far."
  (let ((tags (exwm-browser-link--get-tags '()))
        (selected '()))
    (catch 'done
      (while t
        (let ((tag (ck/completing-read-in-order
                    "Tag: " (cons "DONE" tags))))
          (if (string= "DONE" tag)
              (throw 'done selected)
            (push tag selected)
            (setq tags (remove tag (if narrow
                                       (exwm-browser-link--get-tags selected)
                                     tags)))))))))

(defun exwm-browser-link--grab-meta (link-name)
  "Prompt for LINK-NAME and a tag set; return (LINK-NAME \"tag ...\")."
  (interactive "sName: ")
  (list link-name (s-join " " (reverse (exwm-browser-link--read-tags)))))

(defun exwm-browser-link--visit-tagged (tags visit-all?)
  "Visit a link carrying every tag in TAGS (all matches when VISIT-ALL?)."
  (let ((links (parseedn-read-str
                (exwm-browser-link--bb "list-tagged" (s-join " " tags)))))
    (if links
        (if visit-all?
            (->> links
                 ht-values
                 (--map (gethash :url it))
                 (-map #'browse-url))
          (let ((n (completing-read "Link: " links nil t)))
            (->> links (gethash n) (gethash :url) browse-url)))
      (message "No links with this tag set!"))))

(defun exwm-browser-link--visit-by-tags (visit-all?)
  "Read a narrowing tag set, then visit matches (all links when empty)."
  (let ((tags (exwm-browser-link--read-tags 'narrow)))
    (if tags
        (exwm-browser-link--visit-tagged tags visit-all?)
      (exwm-browser-link-visit))))

(defun exwm-browser-link-visit-tagged ()
  "Pick a tag set, then visit one matching link."
  (interactive)
  (exwm-browser-link--visit-by-tags nil))

(defun exwm-browser-link-visit-all-tagged ()
  "Pick a tag set, then open every matching link."
  (interactive)
  (exwm-browser-link--visit-by-tags t))

(defun exwm-browser-link-create ()
  "with a firefox window selected, fire this off to create a bookmark at the
current url (grabs it via faked C-l / C-c and the clipboard)"
  (interactive)
  (let ((url
         (progn
           (gui-set-selection 'CLIPBOARD nil)
           (exwm-input--fake-key ?\C-l)
           (sleep-for 0.3)
           (exwm-input--fake-key ?\C-c)
           (let ((waited 0.0)
                 (clip nil))
             (while (and (< waited 2.0)
                         (not (and (stringp clip)
                                   (s-starts-with? "http" clip))))
               (sleep-for 0.1)
               (setq waited (+ waited 0.1))
               (setq clip (ignore-errors
                            (gui-get-selection 'CLIPBOARD))))
             clip))))
    (if (and (stringp url) (s-starts-with? "http" url))
        (let* ((meta (call-interactively #'exwm-browser-link--grab-meta))
               (link-name (car meta))
               (tags (cadr meta)))
          (exwm-browser-link--bb "append-link" link-name url tags))
      (message "exwm-browser-link-create failed: invalid URL (clipboard was %S)"
               url))))

(general-define-key :keymaps 'exwm-mode-map
                    "s-d" #'exwm-browser-link-create)

(defhydra hydra-exwm-browser-link (:exit t :columns 5)
  "exwm browser links"
  ("e" #'exwm-browser-link-visit            "visit link")
  ("t" #'exwm-browser-link-visit-tagged     "visit tagged link")
  ("T" #'exwm-browser-link-visit-all-tagged "visit all tagged links"))


(provide 'config/desktop/browser-links)
