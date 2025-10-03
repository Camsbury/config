{ config, pkgs, ... }:


let
  unstablePkgs = import (import ../pins.nix).unstable {
    config = { allowUnfree = true; };
  };
  spotifyPkgs = import (import ../pins.nix).spotify {
    config = { allowUnfree = true; };
  };

  # cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};
in
  {
    nixpkgs.overlays = [
      (self: super: {

        alias-tips = with builtins; with pkgs;
          callPackage (import ../derivations/alias-tips) {};

        # babashka = with builtins; with pkgs;
        #   callPackage (import ../derivations/babashka) {};

        check-low-battery = with builtins; with pkgs;
          callPackage (import ../derivations/check-low-battery) {};

        # cachix = cachixBall.cachix;

        cmacs = with builtins; with pkgs;
          callPackage (import ../derivations/cmacs) {};

        cmacs-load-path = with builtins; with pkgs;
          callPackage (import ../derivations/cmacs-load-path) {};

        disper = with builtins; with pkgs;
          callPackage (import ../derivations/disper) {};

        gollama = with builtins; with pkgs;
          callPackage (import ../derivations/gollama) {};

        lmstudio = with builtins; with pkgs;
          callPackage (import ../derivations/lmstudio) {};

        pgn-extract = with builtins; with pkgs;
          callPackage (import ../derivations/pgn-extract) {};

        spotify = spotifyPkgs.spotify;

        xndr = super.callPackage (builtins.fetchTarball
          "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};

      } // ( with unstablePkgs; {
        inherit aider-chat;
        inherit bat;
        # inherit dropbox;
        inherit emacs;
        # inherit ollama;
        # inherit gollama;
        # inherit lmstudio;
        # inherit update-nix-fetchgit;
        inherit mu;
      })
      )
      (import ./emacs.nix)
    ];
  }
