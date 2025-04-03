{ config, pkgs, ... }:

let
  discordPkgs = import ../pins/discord.nix {
    config = {
      allowUnfree = true;
    };
  };
in
{
  environment = {
    variables = {
      BROWSER = "brave-browser";
    };
    systemPackages = with pkgs; [
      anki
      aria2
      audacity
      baobab
      brave
      chromium
      discordPkgs.discord
      # element-desktop
      firefox
      gimp
      google-chrome # for certain features
      okular
      peek # screen recorder
      pgn-extract # chess utils
      scid-vs-pc # chess
      signal-desktop
      slack
      spotify # non-free
      tdesktop # telegram
      thunderbird
      transmission_3
      vlc
    ];
  };
}
