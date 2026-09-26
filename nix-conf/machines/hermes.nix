{
  config,
  pkgs,
  sources,
  ...
}:

{
  imports = [
    ../modules/core

    # hardware
    # The Dell profile already imports the Intel CPU and GPU stacks,
    # common/pc/laptop and common/pc/ssd. The lines below name the parts
    # hermes has; they do not switch the nixos-hardware halves on.
    "${sources.nixos-hardware}/dell/xps/13-9310"
    ../modules/hardware/intel-cpu.nix
    ../modules/hardware/intel-graphics.nix
    ../modules/hardware/laptop.nix
    ../modules/hardware/builtin-keyboard.nix

    #functionality
    ../modules/hardware/bluetooth.nix
    ../modules/apps/email.nix
    ../modules/apps/gaming.nix
    ../modules/apps/art.nix
    ../modules/dev/virtualization.nix
  ];

  boot.initrd.luks.devices.crypted.device = "/dev/disk/by-uuid/559bcebb-ef43-4d84-8550-8b371bfb6aa6";
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "hermes";
  users.users.default.name = "camsbury";

  # eDP-1's panel mode, used to size the lock screen and greeter wallpaper.
  ck.theme.screenResolution = "3840x2400";

  services.xserver.xrandrHeads = [
    {
      output = "eDP-1";
      primary = true;
      monitorConfig = ''
        DisplaySize 406 228
      '';
    }
    {
      output = "DP-3";
      monitorConfig = ''
        DisplaySize 508 285
      '';
    }
  ];

  system.stateVersion = "20.03";
}
