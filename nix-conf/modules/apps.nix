{ config, pkgs, ... }:

{
  environment = {
    variables = {
      BROWSER = "brave-browser";
    };
    systemPackages = with pkgs; [
      anki
      audacity
      brave
      chromium
      discord
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
      transmission
      vlc
    ];
  };
}
