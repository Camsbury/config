{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/gaming.nix
    ../modules/intel.nix
    ../modules/nvidia.nix
    ../modules/ssd.nix
    ../modules/music.nix
  ];

  networking.hostName = "functor";

  nix.trustedUsers = [ "root" "monoid" ];

  users.users.monoid = {
    isNormalUser = true;
    home = "/home/monoid";
    extraGroups = ["wheel" "networkmanager" "docker"];
    shell = pkgs.zsh;
  };

  home-manager.users.monoid = import ../modules/home.nix;
}
