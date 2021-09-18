{ config, pkgs, ... }:

{
  imports = [
    ./intel.nix
    ./laptop.nix
    ./ssd.nix
    "${import ../utils/hardware.nix}/dell/xps/13-9310"
  ];

  # hardware = {
  #   nvidiaOptimus.disable = true;
  #   opengl = {
  #     extraPackages = [ pkgs.linuxPackages.nvidia_x11.out ];
  #     extraPackages32 = [ pkgs.linuxPackages.nvidia_x11.lib32 ];
  #   };
  # };

  # Force S3 sleep mode. See README.wiki for details.
  boot.kernelParams = [ "mem_sleep_default=deep" ];

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
