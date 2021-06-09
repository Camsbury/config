{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    nvtop
    steam
    (wineWowPackages.full.override {
      wineRelease = "staging";
      mingwSupport = true;
    })
    (winetricks.override {
      wine = wineWowPackages.staging;
    })
    xorg.xgamma
  ];

  hardware.opengl.driSupport32Bit = true;
}
