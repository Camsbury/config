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
    ./docker.nix
  ];
  environment.systemPackages = with pkgs; [
    babashka
    binutils
    code-maat
    direnv
    (emacsPackages.emacsWithPackages (import ../packages/emacs.nix))
    entr
    gdb
    git
    gitAndTools.git-extras
    gitAndTools.hub
    glibc
    gnumake
    google-cloud-sdk
    kubectl
    loc
    nixfmt
    update-nix-fetchgit
    nodePackages.prettier
    patchelf # patch dynamic libs/bins
    postgresql_11
    python3
    shellcheck
    sloccount
    sqlite
    tmux
  ];
  services.lorri.enable = true;
}
