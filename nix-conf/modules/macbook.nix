{ config, lib, pkgs, ... }:

let
  kernelPackages = config.boot.kernelPackages;
in
  {
    imports = [
      "${import ../utils/hardware.nix}/apple"
    ];

    services = {
      xserver = {
        xkbVariant = "colemak";
        xkbOptions = "caps:escape";
        xrandrHeads = [{
          output = "eDP-1";
          primary = true;
          monitorConfig = ''
            DisplaySize 406 228
          '';
        }];
      };

      udev.extraRules =
        # Disable XHC1 wakeup signal to avoid resume getting triggered some time
        # after suspend. Reboot required for this to take effect.
        lib.optionalString
          (lib.versionAtLeast kernelPackages.kernel.version "3.13")
          ''SUBSYSTEM=="pci", KERNEL=="0000:00:14.0", ATTR{power/wakeup}="disabled"'';
    };
  }
