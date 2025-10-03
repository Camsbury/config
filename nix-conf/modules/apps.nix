{ config, pkgs, ... }:

let
  discordPkgs = import (import ../pins.nix).discord {
    config = {
      allowUnfree = true;
    };
  };
in
{
  services.transmission = {
    enable = true;
    openFirewall = true;
  };

  systemd.tmpfiles.rules = [
    "d ${toString config.services.transmission.settings.download-dir} 0770 transmission transmission - -"
  ];

  environment = {
    variables = {
      BROWSER = "firefox";
    };
    systemPackages = with pkgs; [
      anki
      aria2
      audacity
      baobab
      chromium
      discordPkgs.discord
      # element-desktop
      firefox
      gimp
      google-chrome # for certain features
      peek # screen recorder
      pgn-extract # chess utils
      scid-vs-pc # chess
      # signal-desktop
      slack
      spotify # non-free
      tdesktop # telegram
      thunderbird
      vlc
      zathura
    ];
  };
}
