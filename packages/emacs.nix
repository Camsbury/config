epkgs:

let
  melpas = with epkgs.melpaPackages; [
    avy
    benchmark-init
    buffer-move
    cider
    circe
    clj-refactor
    command-log-mode
    company
    company-cabal
    company-ghc
    company-jedi
    company-lsp
    counsel
    counsel-projectile
    dante
    dash
    dash-functional
    define-word
    dockerfile-mode
    doom-themes
    doom-modeline
    dotenv-mode
    ein
    elixir-mode # elixir
    emacsql
    emacsql-psql
    ess
    evil
    evil-commentary
    evil-magit
    evil-multiedit
    evil-smartparens
    evil-surround
    evil-visualstar
    exec-path-from-shell
    f
    flycheck
    flycheck-haskell
    flycheck-irony
    flycheck-popup-tip
    flycheck-credo # elixir
    flycheck-dialyxir # elixir
    flycheck-elixir # elixir
    flycheck-mix # elixir
    forge
    format-all
    general
    git-timemachine
    helm-dash
    hl-todo
    hlint-refactor
    hydra
    irony
    irony-eldoc
    ivy
    ivy-hydra
    js2-mode
    json-navigator
    keychain-environment
    know-your-http-well
    lsp-haskell
    lsp-mode
    lsp-ui
    magit
    markdown-preview-mode
    mediawiki
    nav-flash
    nix-mode
    nov
    ob-async
    ob-http
    ob-ipython
    org-bullets
    paredit
    paxedit
    prettier-js
    projectile
    pylint
    py-isort
    racket-mode
    rainbow-delimiters
    rainbow-identifiers
    ranger
    restart-emacs
    rjsx-mode
    s
    slack
    smartparens
    smex
    sqlup-mode
    tree-mode
    use-package
    visual-fill-column
    web
    wgrep
    yaml-mode
    yapfify # python-lsp
    yasnippet
  ];
  elpas = with epkgs.elpaPackages; [
    rainbow-mode
    undo-tree
  ];
  others = with epkgs; [
    agda2-mode
    company-postgresql
    etymology-of-word
    key-quiz
    org-clubhouse
    # slack
  ];
in
  melpas ++ elpas ++ others
