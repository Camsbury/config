(setq exwm-browser-set-link-script
      "~/projects/Camsbury/config/manage_browser_links.clj")

(defun exwm-browser-link--grab-meta (link-name tags)
  (interactive "sName: \nsTags (space-separated): ")
  (list link-name tags))

;;; TODO: add tag, remove, and "get tagged" actions

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

(defun exwm-browser-link-visit-tagged ()
  "list tags for browser links"
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


(provide 'config/desktop/browser-links)
