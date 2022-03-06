{ config, pkgs, lib, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../overlays/core.nix
    ../private.nix

    ./audio.nix
    ./apps.nix
    ./boot.nix
    ./cmacs.nix
    ./desktop.nix
    ./dev.nix
    ./dropbox.nix
    ./search.nix
    ./security.nix
    ./shell.nix
    ./user.nix
    ./utils.nix
  ];

  environment.variables = {
    SHAREPATH =
      "/home/${toString config.users.users.default.name}/Dropbox/lxndr";
  };

  networking.networkmanager.enable = true;

  nix = {
    settings = {
      extra-experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [
        "https://hydra.iohk.io"
      ];
      trusted-substituters = [
        "https://hydra.iohk.io"
      ];
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
    };
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixpkgs-unstable=${../utils/unstable.nix}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
