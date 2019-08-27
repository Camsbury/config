{ config, pkgs, ... }:

{
  imports = [
    ../overlays/xps.nix
  ];

  hardware = {
    nvidiaOptimus.disable = true;
    opengl = {
      extraPackages = [ pkgs.linuxPackages.nvidia_x11.out ];
      extraPackages32 = [ pkgs.linuxPackages.nvidia_x11.lib32 ];
    };
  };

  services.xserver.xrandrHeads = [
    { output = "eDP-1";
      primary = true;
      monitorConfig = ''
        DisplaySize 406 228
      '';
    }
    { output = "DP-3";
      monitorConfig = ''
        DisplaySize 508 285
      '';
    }
  ];
}
