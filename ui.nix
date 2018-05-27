# The UI module is where I make my computer look and feel right.

{ config, pkgs, ... }:

let
  machine = (import ./machine.nix);
in
  {
    services.xserver = {
      # Enable the X11 windowing system.
      enable = true;

      # Set keyboard layout
      layout = "us";

      displayManager = {
        sddm.enable = true;
        # lightdm.enable = true;
      };

      # desktopManager = {
        # plasma5.enable = true;
        # xfce.enable = true;
        # gnome3.enable = true;
      # };

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
        then { xkbVariant = "colemak";
               xkbOptions = "caps:escape";
             } else {});

  }
