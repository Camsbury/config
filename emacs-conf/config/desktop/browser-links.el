(setq exwm-browser-set-link-script
      "~/projects/Camsbury/config/manage_browser_links.clj")

(defun exwm-browser-link--grab-meta (link-name tags)
  (interactive "sName: \nsTags (space-separated): ")
  (list link-name tags))

;;; TODO: implement other functions

(defun exwm-browser-link--visit-tagged (tag)
  "Select a link to visit in the browser"
  (let ((links
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-tagged " tag)))))
    (ivy-read
     "Link: "
     links
     :action
     (lambda (n)
       (->> links (gethash n) (gethash :url) browse-url)))))

(defun exwm-browser-link-visit-tagged () ;; TODO: edit to take multiple tags
  "choose tags to filter by"
  (interactive)
  (let ((tags
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-tags")))))
    (ivy-read
     "Tag: "
     (append tags nil)
     :action
     (lambda (tag)
       (exwm-browser-link--visit-tagged tag)))))

(defun exwm-browser-link--visit-all-tagged (tag)
  "visit all links for given tag"
  (let ((links
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-tagged " tag)))))
    (->> links
         ht-values
         (--map (gethash :url it))
         (-map #'browse-url))))

(defun exwm-browser-link-visit-all-tagged ()
  "choose tag to visit"
  (interactive)
  (let ((tags
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-tags")))))
    (ivy-read
     "Tag: "
     (append tags nil)
     :action
     (lambda (tag)
       (exwm-browser-link--visit-all-tagged tag)))))

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

(defun exwm-browser-link-create ()
  "with a brave browser selected and my extension installed, fire this off to
create a bookmark at the current url"
  (interactive)
  (let ((url
         (progn
           (exwm-input--fake-key ?\C-\S-u)
           (sleep-for 1)
           (setq url (current-kill 0)))))
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
  ("e" #'exwm-browser-link-visit        "visit link")
  ("t" #'exwm-browser-link-visit-tagged "visit tagged link"))


(provide 'config/desktop/browser-links)
