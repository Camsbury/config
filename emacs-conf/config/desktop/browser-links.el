(require 'prelude)
(require 'hydra)
(require 'browse-url)


(defvar exwm-browser-set-link-script)
(setq exwm-browser-set-link-script
      "~/projects/Camsbury/config/manage_browser_links.clj")

(defun exwm-browser-link-visit ()
  "Select a link to visit in the browser"
  (interactive)
  (let ((links
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-all")))))
    (ivy-read
     "Link: "
     links
     :action
     (lambda (n)
       (open-brave)
       (->> links (gethash n) (gethash :url) browse-url)))))

(defun exwm-browser-link--grab-meta (link-name tags)
  (interactive "sName: \nsTags (space-separated): ")
  (list link-name tags))

(defun exwm-browser-link--visit-tagged (tags visit-all?)
  "Select a link to visit in the browser"
  (let ((links
         (parseedn-read-str
          (shell-command-to-string
           (concat
            "bb -f "
            exwm-browser-set-link-script
            " list-tagged '"
            (s-join " " tags)
            "'")))))
    (if links
        (if visit-all?
            (->> links
                 ht-values
                 (--map (gethash :url it))
                 (-map #'browse-url))
          (ivy-read
           "Link: "
           links
           :action
           (lambda (n)
             (->> links (gethash n) (gethash :url) browse-url))))
      (message "No links with this tag set!"))))

(defun exwm-browser-link--get-tags (selected)
  (parseedn-read-str
   (shell-command-to-string
    (concat
     "bb -f "
     exwm-browser-set-link-script
     " list-tags '"
     (s-join " " selected)
     "'"))))

(defun exwm-browser-link--build-tags (tags selected &optional visit-all?)
  (ivy-read
   "Tag: "
   (append tags '("DONE"))
   :preselect "DONE"
   :action
   (lambda (tag)
     (if (string= "DONE" tag)
         (if selected
             (exwm-browser-link--visit-tagged selected visit-all?)
           (exwm-browser-link-visit))
       (let* ((selected (cons tag selected))
              (tags
               (->> selected
                    exwm-browser-link--get-tags
                    (remove tag)
                    )))
         (print selected)
         (exwm-browser-link--build-tags tags selected visit-all?))))))

(defun exwm-browser-link-visit-tagged ()
  "choose tags to filter by"
  (interactive)
  (let ((tags (exwm-browser-link--get-tags '())))
    (exwm-browser-link--build-tags tags '())))

(defun exwm-browser-link-visit-all-tagged ()
  "choose tag to visit"
  (interactive)
  (let ((tags (exwm-browser-link--get-tags '())))
    (exwm-browser-link--build-tags tags '() t)))

(defun exwm-browser-link-create ()
  "with a brave browser selected and my extension installed, fire this off to
create a bookmark at the current url"
  (interactive)
  (let ((url
         (progn
           (exwm-input--fake-key ?\C-\S-u)
           (sleep-for 1)
           (current-kill 0))))
    (if (s-starts-with? "http" url)
        (let* ((meta (call-interactively #'exwm-browser-link--grab-meta))
               (link-name (car meta))
               (tags (cadr meta)))
          (shell-command
           (concat
            "bb -f "
            exwm-browser-set-link-script
            " append-link '"
            link-name
            "' '"
            url
            "' '"
            tags
            "'")))
      (message "exwm-browser-link-create failed: invalid URL"))))

(general-define-key :keymaps 'exwm-mode-map
                    "s-d" #'exwm-browser-link-create)

(defhydra hydra-exwm-browser-link (:exit t :columns 5)
  "exwm browser links"
  ("e" #'exwm-browser-link-visit            "visit link")
  ("t" #'exwm-browser-link-visit-tagged     "visit tagged link")
  ("T" #'exwm-browser-link-visit-all-tagged "visit all tagged links"))


(provide 'config/desktop/browser-links)
