{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    anki
    audacity
    brave
    chromium
    discord
    firefox
    gimp
    okular
    peek # screen recorder
    pgn-extract # chess utils
    scid-vs-pc #chess
    signal-desktop
    slack
    spotify # non-free
    tdesktop # telegram
    transmission
    vlc
  ];
}
