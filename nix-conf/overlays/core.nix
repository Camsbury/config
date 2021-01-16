{ config, pkgs, ... }:


let
  unstablePkgs = import ../utils/unstable.nix { config = { allowUnfree = true; }; };
  cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};
in
  {
    nixpkgs.overlays = [
      (self: super: {

        alias-tips = with builtins; with pkgs;
          callPackage (import ../derivations/alias-tips) {};

        babashka = with builtins; with pkgs;
          callPackage (import ../derivations/babashka) {};

        check-low-battery = with builtins; with pkgs;
          callPackage (import ../derivations/check-low-battery) {};

        cachix = cachixBall.cachix;

        cmacs = with builtins; with pkgs;
          callPackage (import ../derivations/cmacs) {};

        cmacs-load-path = with builtins; with pkgs;
          callPackage (import ../derivations/cmacs-load-path) {};

        xndr = super.callPackage (builtins.fetchTarball
          "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
        } // ( with unstablePkgs; {
          inherit bat;
          inherit brave;
          inherit chromium;
          inherit dropbox;
          inherit discord;
        })
      )
      (import ./emacs.nix)
    ];
  }
