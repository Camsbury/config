{ config, pkgs, lib, ... }:

{
  environment.variables = {
    EMACSLOADPATH = "${(pkgs.emacsPackages.emacsWithPackages (import ../packages/emacs.nix)).deps}/share/emacs/site-lisp";
  };
  services.displayManager.defaultSession = "none+exwm";
  services.xserver = {
    displayManager = {
      sessionCommands = "${pkgs.xorg.xhost}/bin/xhost +SI:localuser:$USER";
    };
    windowManager = {
      session = lib.singleton {
        name = "exwm";
        start = "${pkgs.cmacs}/bin/cmacs";
      };
    };
  };
}
