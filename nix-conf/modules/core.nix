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

  networking.networkmanager.enable = true;

  nix = {
    binaryCaches = [
      "https://hydra.iohk.io"
      "https://hie-nix.cachix.org"
    ];
    trustedBinaryCaches = [
      "https://hydra.iohk.io"
      "https://hie-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "hie-nix.cachix.org-1:EjBSHzF7VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
    ];
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixpkgs-unstable=${../utils/unstable.nix}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs.config.allowUnfree = true;
}
