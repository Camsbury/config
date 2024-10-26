let
  pkgs = import ./pinned.nix {
    overlays = [(import ./overlays.nix)];
  };
in

with pkgs;
rec {
  qmkSource = fetchgit {
    url = "https://github.com/qmk/qmk_firmware";
    rev = "6dfe915e26d7147e6c2bed495d3b01cf5b21e6ec";
    sha256 = "0f8hpzhz76rky22i2fjjhdjjlk86bgpvywnqw8br5dxzczw05glw";
    fetchSubmodules = true;
  };

  layout = stdenv.mkDerivation rec {
    name = "ergodox_ez_camerak.hex";

    src = qmkSource;

    buildInputs = [
      dfu-programmer
      dfu-util
      avrdude
      pkgsCross.avr.libcCross
      pkgsCross.avr.buildPackages.binutils
      pkgsCross.avr.buildPackages.gcc8
      pkgsCross.arm-embedded.buildPackages.gcc
      which
    ];

    postPatch = ''
      mkdir keyboards/ergodox_ez/keymaps/camerak
      cp ${./config.h} keyboards/ergodox_ez/keymaps/camerak/config.h
      cp ${./keymap.c} keyboards/ergodox_ez/keymaps/camerak/keymap.c
    '';

    configurePhase = ''
      export LD_LIBRARY_PATH=${hidapi}/lib:$LD_LIBRARY_PATH
    '';

    buildPhase = "${qmk}/bin/qmk compile -kb ergodox_ez -km camerak";

    installPhase = "cp *.hex $out";
  };

  flash = writeShellScript "flash.sh" ''
    ${teensy-loader-cli}/bin/teensy-loader-cli \
      -v \
      --mcu=atmega32u4 \
      -w ${layout} && exit
  '';

  meta.targets = [ "layout" ];
}
