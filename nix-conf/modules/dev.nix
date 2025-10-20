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
    gitAndTools.git-extras
    gitAndTools.hub
    glibc
    grip
    gnumake
    google-cloud-sdk
    kubectl
    nodePackages.livedown
    nixfmt-rfc-style
    update-nix-fetchgit
    nodePackages.prettier
    pandoc
    patchelf # patch dynamic libs/bins
    python3
    shellcheck
    sloccount
    sqlite
    tmux
  ];
  services.lorri.enable = true;
}
