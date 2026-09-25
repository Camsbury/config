{ config, pkgs, ... }:

# The graphical session: X, the display manager, fonts, notifications, and
# the desktop pieces imported below.
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
  ];

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts
      dejavu_fonts
      go-font
      google-fonts
      noto-fonts
      powerline-fonts
      roboto-mono
      ubuntu-classic
    ];
  };

  services.xserver = {
    enable = true;
    displayManager.lightdm.enable = true;
  };

  # Lets cmacs's ck/restart-display-manager recover a broken session.
  security.sudo.extraRules = [
    {
      users = [ "ALL" ];
      commands = [
        {
          command = "/usr/bin/env systemctl restart display-manager.service";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
