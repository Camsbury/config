epkgs:

let
  melpas = with epkgs.melpaPackages; [
    alarm-clock
    alda-mode
    all-the-icons-ivy-rich
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
    command-log-mode
    company
    company-cabal
    company-c-headers
    company-ghc
    company-go
    company-jedi
    company-lsp
    counsel
    counsel-projectile
    dante
    dash
    dash-functional
    datomic-snippets
    define-word
    direnv
    docker
    dockerfile-mode
    doom-themes
    doom-modeline
    dotenv-mode
    dumb-jump
    ein
    elixir-mode # elixir
    emacsql
    emacsql-sqlite
    emacsql-psql
    ess
    esup
    evil
    evil-commentary
    evil-magit
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
    go-mode
    helm-dash
    idris-mode
    hl-todo
    hlint-refactor
    html-to-hiccup
    hydra
    ivy
    ivy-hydra
    ivy-xref
    js2-mode
    json-navigator
    kaocha-runner
    keychain-environment
    # know-your-http-well
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
    restart-emacs
    rjsx-mode
    rust-mode
    s
    # slack
    slime
    smex
    sqlup-mode
    tree-mode
    use-package
    uuid
    vega-view
    # visual-fill-column
    wgrep
    which-key
    yaml-mode
    yapfify # python-lsp
    yasnippet
  ];
  elpas = with epkgs.elpaPackages; [
    chess
    emms
    exwm
    rainbow-mode
    undo-tree
  ];
  others = with epkgs; [
    agda2-mode
    astyle
    clojure-essential-ref-nov
    company-postgresql
    etymology-of-word
    explain-pause-mode
    ivy-cider
    re-jump
  ];
in
  melpas ++ elpas ++ others
