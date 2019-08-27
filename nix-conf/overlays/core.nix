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
              sha256 = "1svic2b2msbwzfx3qxfglxp0jjzy3p3v78273wab942zh822ld8b";
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

        rural = super.rustPlatform.buildRustPackage rec {
          pname = "rural";
          version = "0.8.1";
          src = super.fetchFromGitHub {
            owner  = "saghm";
            repo   = pname;
            rev    = "be6f7ac7b4ea926d0c6085819d9b4189206914d9";
            sha256 = "1z87dlkvla1alf2whjllf999kl3z18kjjsl7pa5y68amwhd9f2sj";
          };
          cargoSha256 = (if super.stdenv.hostPlatform.system == "x86_64-darwin"
          then "1z4r50qvqzywdcn2wybrajdz7bdhwrbzpm072brhqm4vfxyf23rk"
          else "1gwsynnh42byy9ls3zzi48mpz75l7zrvcdim6q4i8jvyj0h1lzx3");


          propagatedBuildInputs = [
            self.pkg-config
            self.openssl
          ];

          buildInputs = super.stdenv.lib.optionals super.stdenv.isDarwin [ self.darwin.Security self.darwin.apple_sdk.frameworks.CoreServices ];

          doCheck = false;

          meta = with super.stdenv.lib; {
            homepage    = https://github.com/saghm/rural;
            license     = with licenses; [ mit ];
            platforms   = platforms.all;
          };
        };

        xndr = super.callPackage (builtins.fetchTarball
          "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {pkgs = self;};
        } // ( with unstablePkgs; {
          inherit beam;
          inherit bat;
          inherit chromium;
          inherit dropbox;
          inherit spotify; # non-free
          inherit steam;
        })
      )
      (import ./emacs.nix)
    ];
  }
