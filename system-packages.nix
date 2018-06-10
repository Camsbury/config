# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

let
  unstableTarball =
  fetchTarball
    https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
in {
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enablePepperFlash = true;
      enablePepperPDF = true;
    };

    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    ack
    ag
    autojump
    bear
    cargo
    carnix
    chromium
    conky
    curl
    dmenu
    dropbox-cli # bad version, should PR
    dzen2
    exa
    fd
    firefox
    fzf
    gcc
    gdb
    geoclue2
    ghc
    git
    gitAndTools.hub
    gnumake
    gnutls
    haskellPackages.Cabal_2_2_0_0
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    haskellPackages.xmonad-extras
    htop
    irony-server
    libnotify
    man-pages
    nix-repl
    notify-osd
    nox
    oh-my-zsh
    openssh
    python3
    redshift
    ripgrep
    shellcheck
    spotify # non-free
    steam # non-free
    sqlite
    tldr
    udisks
    unzip
    valgrind
    vim
    vlc
    weechat
    wget
    xbindkeys
    xclip
    xorg.xbacklight
    xorg.xmodmap
    zsh
  ] ++ [
    unstable.bat
  ] ++ [
    (import ./emacs.nix { inherit pkgs; })
  ];
}
