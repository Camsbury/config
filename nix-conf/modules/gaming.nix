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
  services.flatpak.enable = true;

  hardware.steam-hardware.enable = true;

  environment = {
    systemPackages = with pkgs; [
      lutris
      mesa
      nvtop
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

  hardware.opengl.enable = true;
  hardware.opengl.driSupport32Bit = true;
  hardware.pulseaudio.support32Bit = true;
}
