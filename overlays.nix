let
  unstableTarball = import ./unstable.nix;
    unstable = import unstableTarball { config = {allowUnfree = true;}; };
  cachixBall = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/1d4de0d552ae9aa66a5b8dee5fb0650a4372d148") {};
in
[(self: super: {
  _1password = super.stdenv.mkDerivation rec {
    version = "0.5.5";
    pname = "1password";
    name = "${pname}-${version}";
    src =
      if super.stdenv.hostPlatform.system == "i686-linux" then
        super.fetchzip {
          url = "https://cache.agilebits.com/dist/1P/op/pkg/v${version}/op_linux_386_v${version}.zip";
          sha256 = "14qx69fq1a3h93h167nhwp6gxka8r34295p82kim9grijrx5zz5f";
          stripRoot = false;
        }
      else if super.stdenv.hostPlatform.system == "x86_64-linux" then
        super.fetchzip {
          url = "https://cache.agilebits.com/dist/1P/op/pkg/v${version}/op_linux_amd64_v${version}.zip";
          sha256 = "1svic2b2msbwzfx3qxfglxp0jjzy3p3v78273wab942zh822ld8b";
          stripRoot = false;
        }
      else if super.stdenv.hostPlatform.system == "x86_64-darwin" then
        super.fetchzip {
          url = "https://cache.agilebits.com/dist/1P/op/pkg/v${version}/op_darwin_amd64_v${version}.zip";
          sha256 = "1s6gw2qwsbhj4z9nrwrxs776y45ingpfp9533qz0gc1pk7ia99js";
          stripRoot = false;
        }
      else throw "Architecture not supported";

    installPhase = ''
      install -D op $out/bin/op
    '';
    postFixup = super.stdenv.lib.optionalString super.stdenv.isLinux ''
      patchelf \
        --set-interpreter $(cat $NIX_CC/nix-support/dynamic-linker) \
        $out/bin/op
    '';

    meta = with super.stdenv.lib; {
      description  = "1Password command-line tool";
      homepage     = https://support.1password.com/command-line/;
      downloadPage = https://app-updates.agilebits.com/product_history/CLI;
      maintainers  = with maintainers; [ joelburget ];
      license      = licenses.unfree;
      platforms    = [ "i686-linux" "x86_64-linux" "x86_64-darwin" ];
    };
  };

  bat = unstable.bat;
  cachix = cachixBall.cachix;
  chromium = unstable.chromium;
  dropbox = unstable.dropbox;
  emacs = import ./emacs.nix { pkgs = unstable; };
  haskellPackages = unstable.haskellPackages;
  spotify = unstable.spotify; # non-free
  steam = unstable.steam;
  xndr = super.callPackage (builtins.fetchTarball
    "https://github.com/Camsbury/xndr/archive/094be18.tar.gz") {};
})]
