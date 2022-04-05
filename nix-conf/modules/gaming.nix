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
  # programs.steam.enable = true;

  xdg.portal.enable = true;
  services.flatpak.enable = true;

  environment = {
    systemPackages = with pkgs; [
      lutris
      nvtop
      # steam
      sc-controller
      vulkan-tools
      (winePkgs.wineWowPackages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      (winePkgs.winetricks.override {
        wine = wineWowPackages.staging;
      })
      xdg-user-dirs
      xorg.xgamma
    ];
  };

  # nixpkgs.overlays = [
  #   (self: super: {
  #     steam = steamPkgs.steam;
  #   })
  # ];

  # hardware.opengl.enable = true;
  # hardware.opengl.driSupport32Bit = true;
}
