{ pkgs, ... }:

# Chat and mail clients.
{
  environment.systemPackages = with pkgs; [
    discord
    # element-desktop
    signal-desktop
    slack
    telegram-desktop
    thunderbird
  ];
}
