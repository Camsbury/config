{ config, pkgs, ... }:

let
  emacs = import ./emacs.nix {inherit pkgs;};
in
  {
    # nix.extraOptions = ''
    #   binary-caches-parallel-connections = 50
    # '';

    # List packages installed in system profile. To search by name, run:
    # $ nix-env -qaP | grep wget
    environment.systemPackages = with pkgs; [
        ag
        bat
        exa
        gitAndTools.git-extras
        gitAndTools.hub
        htop
        httpie
        leiningen
        loc
        mu
        python36
        python36Packages.jedi
        python36Packages.python-language-server
        python36Packages.pyls-isort
        python36Packages.pyls-mypy
        python36Packages.yapf
        ripgrep
        shellcheck
        sourceHighlight
        sqlite
        tldr
        tree
        wget
      ] ++ [
        emacs
      ];

    nixpkgs.overlays = import ./darwin-overlays.nix;

    environment.shellAliases = {
      emacs = "${emacs}";
    };

    # Use a custom configuration.nix location.
    # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
    # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

    # Auto upgrade nix package and the daemon service.
    # services.nix-daemon.enable = true;
    # nix.package = pkgs.nix;

    # Create /etc/bashrc that loads the nix-darwin environment.
    # programs.bash.enable = true;
    # programs.zsh.enable = true;
    # programs.fish.enable = true;

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 3;

    # You should generally set this to the total number of logical cores in your system.
    # $ sysctl -n hw.ncpu
    nix.maxJobs = 8;
    nix.buildCores = 8;
  }
