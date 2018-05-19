# The UI module is where I make my computer look and feel right.

{ config, pkgs, ... }:

{
  services.xserver = {
    # Enable the X11 windowing system.
    enable = true;

    # Set keyboard layout
    layout = "us";
    xkbVariant = "colemak";
    xkbOptions = "caps:escape";

    displayManager = {
      sddm.enable = true;
      # lightdm.enable = true;
    };

    desktopManager = {
      plasma5.enable = true;
      # xfce.enable = true;
      # gnome3.enable = true;
    };

    #windowManager = {
    #  xmonad.enable = true;
    #  twm.enable = true;
    #  icewm.enable = true;
    #  i3.enable = true;
    #  default = "xmonad";
    #};
  };
}
