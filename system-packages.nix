# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ack
    ag
    autojump
    chromium
    curl
    dropbox-cli #bad version, should PR
    exa
    firefox
    fzf
    geoclue2
    git
    gitAndTools.hub
    gnumake
    gnutls
    oh-my-zsh
    openssh
    redshift
    ripgrep
    shellcheck
    spotify #unfree
    tldr
    vim
    wget
    xclip
    zsh
  ] ++ [
    (import ./emacs.nix { inherit pkgs; })
  ];
}
