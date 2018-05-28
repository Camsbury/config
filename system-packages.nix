# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ack
    ag
    autojump
    bear
    chromium
    conky
    curl
    dmenu
    dropbox-cli # bad version, should PR
    dzen2
    exa
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
    man-pages
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
