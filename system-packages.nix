# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    autojump
    chromium
    curl
    emacs
    firefox
    git
    gnumake
    gnutls
    oh-my-zsh
    openssh
    vim
    wget
    xclip
    zsh
  ];
}
