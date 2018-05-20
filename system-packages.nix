# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    autojump
    chromium
    curl
    firefox
    geoclue2
    git
    gnumake
    gnutls
    oh-my-zsh
    openssh
    vim
    wget
    xclip
    zsh
  ] ++ [
    (import ./emacs.nix { inherit pkgs; })
  ];
}
