;; -*- lexical-binding: t; -*-
(require 'prelude)
(require 'core/keys-base)
(require 'browse-url)
(require 'lib/utils)

(declare-functions "config/desktop/commands/launchers" ck/open-firefox)
(declare-functions "exwm-input" exwm-input--fake-key)
(declare-vars exwm-mode-map)


(defvar exwm-browser-set-link-script
  "~/projects/Camsbury/config/manage_browser_links.clj")

(defun exwm-browser-link-visit ()
  "Select a link to visit in the browser"
  (interactive)
  (let ((links
         (parseedn-read-str
          (shell-command-to-string
           (concat "bb -f " exwm-browser-set-link-script " list-all")))))
    (let ((n (completing-read "Link: " links nil t)))
      (ck/open-firefox)
      (->> links (gethash n) (gethash :url) browse-url))))

(defun exwm-browser-link--build-new-tags (tags selected fn)
  ;; DONE leads the candidate list (order preserved), so it starts
  ;; preselected and a bare RET finishes the tag set (the old ivy
  ;; :preselect behavior).
  (let ((tag (ck/completing-read-in-order
              "Tag: " (cons "DONE" tags))))
    (if (string= "DONE" tag)
        (funcall fn selected)
      (let* ((selected (cons tag selected))
             (tags     (remove tag tags)))
        (exwm-browser-link--build-new-tags tags selected fn)))))

(defun exwm-browser-link--grab-meta (link-name)
  (interactive "sName: ")
  ;; this needs to take space separated tags...
  (let ((exwm-browser-link--new-tags '()))
    (exwm-browser-link--build-new-tags
     (exwm-browser-link--get-tags nil)
     nil
     (lambda (to-add) (setq exwm-browser-link--new-tags (append to-add nil))))
    (list link-name (s-join " " exwm-browser-link--new-tags))))

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
          (let ((n (completing-read "Link: " links nil t)))
            (->> links (gethash n) (gethash :url) browse-url)))
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
  (let ((tag (ck/completing-read-in-order
              "Tag: " (cons "DONE" tags))))
    (if (string= "DONE" tag)
        (if selected
            (exwm-browser-link--visit-tagged selected visit-all?)
          (exwm-browser-link-visit))
      (let* ((selected (cons tag selected))
             (tags
              (->> selected
                   exwm-browser-link--get-tags
                   (remove tag))))
        (exwm-browser-link--build-tags tags selected visit-all?)))))

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
