{ config, pkgs, ... }:

let
  steamPkgs = import ../pins/steam.nix {
    config = {
      allowUnfree = true;
    };
  };
  winePkgs  = import ../pins/wine.nix {
    config = {
      allowUnfree = true;
    };
  };
in
{
  environment.systemPackages = with pkgs; [
    nvtop
    steamPkgs.steam
    (winePkgs.wineWowPackages.full.override {
      wineRelease = "staging";
      mingwSupport = true;
    })
    (winePkgs.winetricks.override {
      wine = wineWowPackages.staging;
    })
    xorg.xgamma
  ];

  hardware.opengl.driSupport32Bit = true;
}
