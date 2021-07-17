epkgs:

let
  melpas = with epkgs.melpaPackages; [
    alarm-clock
    alda-mode
    all-the-icons-ivy-rich
    astyle
    async
    attrap
    avy
    # benchmark-init
    bind-key # use package dep
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
    company-jedi
    counsel
    counsel-projectile
    csharp-mode
    dante
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
    lsp-mode
    lsp-ui
    magit
    magit-todos
    markdown-preview-eww
    markdown-preview-mode
    nav-flash
    nix-mode
    nix-update
    nov
    ob-async
    ob-elixir
    ob-http
    ob-ipython
    org-alert
    org-bullets
    origami
    paredit
    parseedn
    prettier-js
    prodigy
    projectile
    pylint
    py-isort
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
    # slack
    slime
    smex
    string-edit
    sqlup-mode
    tree-mode
    ts
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
    ivy-cider
    re-jump
    evil-magit
  ];
in
  melpas ++ elpas ++ others
