{ config, pkgs, ... }:

{
  imports = [
    ../modules/core.nix
    ../modules/crypto.nix
    ../modules/cuda.nix
    ../modules/gaming.nix
    ../modules/intel.nix
    ../modules/nvidia.nix
    ../modules/ssd.nix
    ../modules/music.nix
    ../modules/tract.nix
    ../modules/email.nix
    ../modules/windows.nix
  ];

  networking.hostName = "functor";

  nix.trustedUsers = [
    "root"
    "monoid"
  ];

  users.users.monoid = {
    home = "/home/monoid";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    isNormalUser = true;
    shell = pkgs.zsh;
  };

  home-manager.users.monoid = import ../modules/home.nix;
}
