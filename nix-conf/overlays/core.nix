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
              sha256 = "03m0vxhghzf4zq7k2f1afkc5ixf0qwiiypqjfjgpqpfng7g9ang7";
              stripRoot = false;
            };
          }
        );

        cachix = cachixBall.cachix;

        python36 = super.python36.override {
          packageOverrides = (
            pythonSelf: pythonSuper:
              let
                buildPythonPackage = pythonSuper.buildPythonPackage;
                fetchPypi = pythonSuper.fetchPypi;
              in
                {
                  pylint = pythonSuper.pylint.overridePythonAttrs (
                    oldAttrs: { doCheck = false; }
                  );
                }
          );
        };

        xndr = super.callPackage (builtins.fetchTarball
          "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
        } // ( with unstablePkgs; {
          inherit bat;
          inherit brave;
          inherit chromium;
          inherit dropbox;
          inherit slack;
          inherit spotify; # non-free
          inherit steam;
        })
      )
      (import ./emacs.nix)
    ];
  }
