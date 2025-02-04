{ config, pkgs, ... }:

let
  # steamPkgs = import ../pins/steam.nix {
  #   config = {
  #     allowUnfree = true;
  #   };
  # };
  winePkgs  = import ../pins/wine.nix {
    config = {
      allowUnfree = true;
    };
  };
in
{
  programs.steam.enable = true;

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };
  # services.flatpak.enable = true;

  hardware.steam-hardware.enable = true;

  environment = {
    systemPackages = with pkgs; [
      winePkgs.lutris
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

  hardware.opengl = {
    enable = true;
    # driSupport = true;
    driSupport32Bit = true;
  };
  hardware.pulseaudio.support32Bit = true;
}
