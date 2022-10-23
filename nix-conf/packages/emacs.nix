epkgs:

let
  melpas = with epkgs.melpaPackages; [
    alarm-clock
    alda-mode
    all-the-icons-ivy-rich
    # ammonite-term-repl # scala
    astyle
    async
    attrap
    avy
    # benchmark-init
    bind-key # use package dep
    browse-at-remote
    buffer-move
    cargo
    cider
    circe
    circe-notifications
    clj-refactor
    clojars
    clojure-essential-ref-nov
    command-log-mode
    company
    company-cabal
    company-c-headers
    company-go
    counsel
    counsel-projectile
    counsel-pydoc
    csharp-mode
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
    ein
    elfeed
    elfeed-org
    elfeed-score
    elixir-mode # elixir
    emacsql
    emacsql-sqlite
    emacsql-psql
    emms
    ess
    # esup
    evil
    evil-collection
    evil-commentary
    evil-mu4e
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
    markdown-preview-eww
    markdown-preview-mode
    nav-flash
    nix-mode
    nix-update
    nov
    # ob-ammonite # scala
    ob-async
    ob-elixir
    ob-http
    ob-ipython
    org-alert
    org-bullets
    org-download
    org-journal
    org-ml
    org-parser
    org-ql
    org-roam
    origami
    paredit
    parseedn
    posframe
    prettier-js
    prodigy
    projectile
    py-isort
    pydoc
    pylint
    pytest
    python-pytest
    racer
    racket-mode
    rainbow-delimiters
    ranger
    reformatter # astyle dep
    request
    # restart-emacs
    rjsx-mode
    rust-mode
    s
    sbt-mode
    scala-mode
    # slack
    slime
    smex
    string-edit
    sqlup-mode
    tree-mode
    treemacs
    treemacs-evil
    treemacs-projectile
    ts
    typescript-mode
    use-package
    uuidgen
    vega-view
    # visual-fill-column
    wgrep
    which-key
    with-simulated-input
    yaml-mode
    yapfify # python-lsp
    yasnippet
  ];
  elpas = with epkgs.elpaPackages; [
    chess
    exwm
    rainbow-mode
    undo-tree
  ];
  others = with epkgs; [
    # agda2-mode
    asoc-el
    company-postgresql
    etymology-of-word
    evil-magit
    ivy-cider
    re-jump
  ];
in
  melpas ++ elpas ++ others
