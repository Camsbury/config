{ config, pkgs, ... }:

let
  codeMaatDer = import ../derivations/code-maat/default.nix;
  code-maat = with builtins; with pkgs; callPackage codeMaatDer {
    inherit stdenvNoCC;
    inherit fetchurl;
  };
in
{
  imports = [
    ./bb-nrepl.nix
    ./docker.nix
    ./postgres.nix
  ];
  environment.systemPackages = with pkgs; [
    babashka
    binutils
    code-maat
    direnv
    (emacsPackages.emacsWithPackages (import ../packages/emacs.nix))
    entr
    gdb
    gh
    git
    git-extras
    hub
    glibc
    grip
    gnumake
    google-cloud-sdk
    kubectl
    loccount
    nixfmt-rfc-style
    update-nix-fetchgit
    nodePackages.prettier
    pandoc
    patchelf # patch dynamic libs/bins
    python3
    shellcheck
    sqlite
    tmux
  ];
  services.lorri.enable = true;
}
