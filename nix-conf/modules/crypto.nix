{ config, pkgs, ... }:

{
  services.trezord.enable = true;
  environment.systemPackages = [pkgs.trezor-udev-rules];
}
