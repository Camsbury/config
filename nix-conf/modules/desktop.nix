{ config, pkgs, ... }:

{
  imports = [
    ./theme.nix
    ./screen_lock.nix
    ./media_keys.nix
    ./login_greeter.nix
  ];
  environment.systemPackages = with pkgs; [
    dunst
    espeak # tts
    feh # wallpapers
    inotify-tools
    libnotify
    redshift
    speechd # tts
    xkb-switch
    xbacklight
    xmodmap
  ];

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts
      dejavu_fonts
      go-font
      noto-fonts
      powerline-fonts
      roboto-mono
      ubuntu-classic
    ];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  services.xserver = {
    autoRepeatDelay = 300;
    autoRepeatInterval = 15;
    enable = true;
    xkb.layout = "us";
    displayManager.lightdm.enable = true;
  };

  time.timeZone = "America/New_York";
}
