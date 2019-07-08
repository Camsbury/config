# The UI module is where I make my computer look and feel right.

{ config, pkgs, ... }:

let
  machine = import ./machine.nix;
in
  {
    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Set keyboard layout
      layout = "us,us";

      displayManager.slim = {
        enable = true;
        theme = pkgs.fetchurl {
          url = "https://github.com/edwtjo/nixos-black-theme/archive/v1.0.tar.gz";
          sha256 = "13bm7k3p6k7yq47nba08bn48cfv536k4ipnwwp1q1l2ydlp85r9d";
        };
      };

      autoRepeatDelay = 250;
      autoRepeatInterval = 20;

      windowManager = {
        xmonad = {
          enable = true;
          enableContribAndExtras = true;
          extraPackages = haskellPackages: [
            haskellPackages.xmonad-contrib
            haskellPackages.xmonad-extras
            haskellPackages.xmonad
          ];
        };
        default = "xmonad";
      };
    } // (if ! machine.ergodox
        then {
               xkbVariant = "colemak,";
               xkbOptions = "caps:escape";
             } else {
               xkbVariant = ",colemak";
             });

  }
