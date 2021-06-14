{ config, pkgs, ... }:

{
  imports = [
    ./screen_lock.nix
  ];
  environment.systemPackages = with pkgs; [
    disper
    dunst
    espeak # tts
    feh # wallpapers
    inotify-tools
    libnotify
    redshift
    xkb-switch
    xorg.xbacklight
    xorg.xmodmap
  ];

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      go-font
      noto-fonts
      powerline-fonts
      roboto-mono
      ubuntu_font_family
    ];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  services.xserver = {
    autoRepeatDelay = 300;
    autoRepeatInterval = 15;
    enable = true;
    layout = "us";
    displayManager.lightdm.enable = true;
  };

  time.timeZone = "America/New_York";
}
