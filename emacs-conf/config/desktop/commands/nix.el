;; -*- lexical-binding: t; -*-
(require 'prelude)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Nix / NixOS

(defun ck/nixos-revision ()
  "Copy the nixpkgs revision the running system was built from."
  (interactive)
  (kill-new
   (string-trim (shell-command-to-string "nixos-version --revision"))))

(defun ck/nixos-rebuild-switch ()
  "Rebuild nixos"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     "nixos-rebuild switch"
     (generate-new-buffer-name "*NixOS Rebuild Switch*"))))

(defun ck/nix-search (pkg)
  "search nixpkgs for pkg"
  (interactive "sPackage: ")
  (async-shell-command
   (concat "nix --quiet --log-format raw search nixpkgs "
           pkg
           " --json \\\n | jq -r '\n     to_entries[]\n     | \"\\(.value.pname) (\\(.value.version)) - \\(.value.description)\"'")

   (generate-new-buffer-name (concat "*Searching for package: " pkg "*"))))

(defvar ck/nixos-options-file "/etc/nixos/options.json"
  "NixOS option docs, published by nix-conf's documentation module.
Each key is an option name such as \"networking.hostName\"; each value
holds its \"type\" and \"description\", among other fields.  The file
covers the nixpkgs modules only: options this repo declares itself
\(such as `ck.theme') are absent unless
`documentation.nixos.includeAllModules' is set.")

(defvar ck/nixos-option-history nil
  "Minibuffer history of `ck/nixos-option'.")

(defconst ck/nixos--placeholder-regexp "<[^>]*>"
  "Matches an attribute-set member placeholder such as `<name>'.")

(defconst ck/nixos--list-element-regexp "\\.\\*\\(?:\\.\\|\\'\\)"
  "Matches a list-element segment `*' in an option name.")

(defun ck/nixos--options ()
  "Read `ck/nixos-options-file' into a hash table keyed by option name.
The file is read on every call: parsing takes well under a second, and a
fresh read always matches the most recent rebuild."
  (unless (file-readable-p ck/nixos-options-file)
    (user-error "%s is missing; rebuild the system to publish it"
                ck/nixos-options-file))
  (with-temp-buffer
    (insert-file-contents ck/nixos-options-file)
    (json-parse-buffer :object-type 'hash-table)))

(defun ck/nixos--option-summary (entry)
  "Return the type and first description paragraph of option ENTRY.
The type is cut to 40 columns: some types spell out a whole regexp and
would push the description out of view."
  (let ((description (gethash "description" entry "")))
    (concat
     (propertize (truncate-string-to-width (gethash "type" entry "")
                                           40 nil nil "…")
                 'face 'font-lock-type-face)
     "  "
     (propertize
      (string-join
       (split-string (car (split-string description "\n\n")))
       " ")
      'face 'completions-annotations))))

(defun ck/nixos--option-table (options)
  "Completion table over the option names in OPTIONS.
Candidates are annotated with their type and description, aligned in a
column after all but the longest names."
  (let* ((column (let ((longest 0))
                   (maphash (lambda (name _)
                              (setq longest (max longest (length name))))
                            options)
                   (min 60 (+ 2 longest))))
         (annotate
          (lambda (name)
            (when-let* ((entry (gethash name options)))
              (concat
               (if (< (+ 2 (length name)) column)
                   (propertize " " 'display `(space :align-to ,column))
                 "  ")
               (ck/nixos--option-summary entry))))))
    (lambda (string predicate action)
      (if (eq action 'metadata)
          `(metadata (category . nixos-option)
                     (annotation-function . ,annotate))
        (complete-with-action action options string predicate)))))

(defun ck/nixos--evaluable-path (name)
  "Cut option NAME before its first list-element segment.
An attribute path cannot index a list, so `a.*.b' evaluates as `a',
the whole list."
  (if (string-match ck/nixos--list-element-regexp name)
      (substring name 0 (match-beginning 0))
    name))

(defun ck/nixos-read-option ()
  "Read an option path, completing over the names in the options file.
Any name is accepted, including ones the file lacks.  The chosen path is
first cut by `ck/nixos--evaluable-path'.  If a placeholder such as
`<name>' remains, the path is offered for editing with point on it,
since `nix eval' needs the concrete attribute name."
  (let ((path (ck/nixos--evaluable-path
               (completing-read "Option: "
                                (ck/nixos--option-table (ck/nixos--options))
                                nil nil nil 'ck/nixos-option-history))))
    (if (string-match ck/nixos--placeholder-regexp path)
        (read-from-minibuffer "Option path: "
                              (cons path (1+ (match-beginning 0)))
                              nil nil 'ck/nixos-option-history)
      path)))

(defun ck/nixos-option (option)
  "Print the value of OPTION in the system built from system.nix.
Evaluates /etc/nixos/system.nix, which passes the npins `sources' the
modules need; `nixos-option' goes through <nixpkgs/nixos> and cannot."
  (interactive (list (ck/nixos-read-option)))
  (async-shell-command
   (concat "nix eval -f /etc/nixos/system.nix "
           (shell-quote-argument (concat "config." option)))
   (generate-new-buffer-name (concat "*Describing Option: " option "*"))))

(defun ck/ergodox-build-and-flash ()
  "Rebuild ergodox"
  (interactive)
  (let ((default-directory "/sudo::"))
    (async-shell-command
     (concat
      "nix-shell /home/"
      (user-login-name)
      "/projects/Camsbury/config/camerak/shell.nix --run exit")
     (generate-new-buffer-name "*Build and Flash Ergodox*"))))

(defun ck/nix-collect-garbage ()
  "Collect garbage"
  (interactive)
  (async-shell-command
   "nix-collect-garbage -d"
   (generate-new-buffer-name "*Nix Collect Garbage*")))

(defun ck/nix-derivation-is-cached? (derivation)
  "Sees if the derivation is cached on the nixos cache"
  (interactive "sDerivation Path: ")
  (shell-command
   (concat
    "nix path-info -r "
    derivation
    " --store https://cache.nixos.org/")))

(provide 'config/desktop/commands/nix)
