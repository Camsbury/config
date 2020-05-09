{ config, pkgs, ... }:


let
  unstablePkgs = import ../utils/unstable.nix { config = { allowUnfree = true; }; };
  cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};
in
  {
    nixpkgs.overlays = [
      (self: super: {
        _1password = super._1password.overrideAttrs (
          oldAttrs: {
            src = super.fetchzip {
              url = "https://cache.agilebits.com/dist/1P/op/pkg/v${
                  super._1password.version
                }/op_linux_amd64_v${
                  super._1password.version
                }.zip";
              sha256 = "1sjv5qrc80fk9yz0cn2yj0cdm47ab3ch8n9hzj9hv9d64gjv4w8n";
              stripRoot = false;
            };
          }
        );

        cachix = cachixBall.cachix;

        xndr = super.callPackage (builtins.fetchTarball
          "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
        } // ( with unstablePkgs; {
          inherit bat;
          inherit brave;
          inherit chromium;
          inherit dropbox;
          inherit slack;
          # inherit spotify; # non-free
          # inherit steam;
        })
      )
      (import ./emacs.nix)
    ];
  }
