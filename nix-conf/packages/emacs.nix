epkgs:

let
  melpas = with epkgs.melpaPackages; [
    aggressive-indent
    aidermacs
    alarm-clock
    alda-mode
    all-the-icons-ivy-rich
    # ammonite-term-repl # scala
    astyle
    async
    attrap
    avy
    # benchmark-init
    beacon
    browse-at-remote
    buffer-move
    cape
    cargo
    cider
    circe
    circe-notifications
    clj-refactor
    clojars
    clojure-essential-ref-nov
    command-log-mode
    company
    company-box
    company-cabal
    company-c-headers
    company-go
    consult # emacs nouveau
    consult-projectile
    corfu
    dante
    dap-mode
    dash
    datomic-snippets
    deadgrep
    define-word
    direnv
    docker
    dockerfile-mode
    doom-themes
    doom-modeline
    dotenv-mode
    dumb-jump
    eca
    ein
    elfeed
    elfeed-org
    elfeed-score
    elixir-mode # elixir
    emacsql
    embark # emacs nouveau
    embark-consult # emacs nouveau
    emms
    ess
    # esup
    evil
    evil-collection
    evil-commentary
    evil-multiedit
    evil-surround
    evil-visualstar
    exec-path-from-shell
    f
    flycheck
    flycheck-haskell
    flycheck-popup-tip
    flycheck-clj-kondo
    flycheck-credo # elixir
    flycheck-dialyxir # elixir
    flycheck-elixir # elixir
    # flycheck-mix # elixir
    flycheck-rust
    forge
    general
    git-timemachine
    github-notifier
    go-mode
    helm-dash
    helpful
    idris-mode
    hl-todo
    hlint-refactor
    ht
    html-to-hiccup
    hydra
    ivy
    ivy-clojuredocs
    ivy-hydra
    ivy-xref
    journalctl-mode
    js2-mode
    json-navigator
    kaocha-runner
    keychain-environment
    # know-your-http-well
    lispy
    lispyville
    lsp-haskell
    lsp-metals
    lsp-mode
    lsp-treemacs
    lsp-ui
    magit
    magit-todos
    marginalia # emacs nouveau
    markdown-preview-eww
    markdown-preview-mode
    nav-flash
    nerd-icons-completion
    nix-mode
    nix-update
    nov
    # ob-ammonite # scala
    ob-async
    ob-elixir
    ob-http
    ob-ipython
    orderless # emacs nouveau
    org-alert
    org-bullets
    org-download
    org-journal
    org-ml
    org-parser
    org-ql
    org-roam
    org-roam-ui
    origami
    paredit
    parseedn
    pkg-info
    pomidor
    posframe
    prettier-js
    prodigy
    projectile
    py-isort
    pydoc
    pylint
    pytest
    python-pytest
    racket-mode
    rainbow-delimiters
    ranger
    reformatter # astyle dep
    request
    # restart-emacs
    rjsx-mode
    rust-mode
    rustic
    s
    sbt-mode
    scala-mode
    # slack
    slime
    smex
    string-edit-at-point
    sqlite3
    sqlup-mode
    tree-mode
    treemacs
    treemacs-evil
    treemacs-projectile
    ts
    typescript-mode
    uuidgen
    vega-view
    vertico # emacs nouveau
    # visual-fill-column
    wgrep
    which-key
    with-simulated-input
    yaml-mode
    yapfify # python-lsp
    yasnippet
  ];
  elpas = with epkgs.elpaPackages; [
    bind-key # use package dep
    chess
    exwm
    kind-icon
    rainbow-mode
    undo-tree
    use-package
  ];
  others = with epkgs; [
    # agda2-mode
    asoc-el
    # company-postgresql
    etymology-of-word
    hide-comnt
    mu4e
    re-jump
  ];
in
  melpas ++ elpas ++ others
