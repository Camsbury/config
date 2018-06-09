# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

{
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enablePepperFlash = true;
      enablePepperPDF = true;
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
    (import ./emacs.nix { inherit pkgs; })
  ];
}
