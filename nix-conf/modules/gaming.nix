{ config, pkgs, ... }:

let
  winePkgs  = import (import ../pins.nix).wine {
    config = {
      allowUnfree = true;
    };
  };
in
{
  programs.steam.enable = true;

  # xdg = {
  #   portal = {
  #     enable = true;
  #     extraPortals = with pkgs; [
  #       xdg-desktop-portal-wlr
  #       xdg-desktop-portal-gtk
  #     ];
  #   };
  # };
  # services.flatpak.enable = true;

  hardware.steam-hardware.enable = true;

  environment = {
    systemPackages = with pkgs; [
      winePkgs.lutris
      joystickwake
      mesa
      nvtopPackages.full
      sc-controller
      vulkan-tools
      (winePkgs.wineWowPackages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      # was used for wc3
      # (winePkgs.winetricks.override {
      #   wine = wineWowPackages.staging;
      # })
      winePkgs.winetricks
      xdg-user-dirs
      xorg.xgamma
    ];
  };

  # nixpkgs.overlays = [
  #   (self: super: {
  #     steam = steamPkgs.steam;
  #   })
  # ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 1000000;
  };

  hardware.graphics = {
    enable = true;
    # driSupport = true;
    enable32Bit = true;
  };
  services.pulseaudio.support32Bit = true;

  systemd.services.joystickwake = {
    description = "joystickwake service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.joystickwake}/bin/joystickwake";
    };
  };

}
