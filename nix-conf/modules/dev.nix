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
  environment = {
    systemPackages = with pkgs; [
      babashka
      binutils
      code-maat
      difftastic
      direnv
      (emacsPackages.emacsWithPackages (import ../packages/emacs.nix))
      entr
      gdb
      gh
      git
      git-extras
      hub
      glibc
      go-grip
      gnumake
      google-cloud-sdk
      kubectl
      loccount
      nixfmt
      update-nix-fetchgit
      pkgs.prettier
      pandoc
      patchelf # patch dynamic libs/bins
      python3
      shellcheck
      sqlite
      tmux
    ];

    variables = {
      DEV_HOME="/home/${toString config.users.users.default.name}/projects";
    };
  };
  services.lorri.enable = true;
}
