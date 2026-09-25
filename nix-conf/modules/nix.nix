{
  lib,
  pkgs,
  sources,
  ...
}:

# Nix itself: daemon settings, nixpkgs configuration, the npins pins, store
# garbage collection, and the tools for managing them.
{
  environment.systemPackages = with pkgs; [
    cachix
    nix-index
    npins
  ];

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.iog.io"
        "https://nix-community.cachix.org"
        "https://cache.nixos-cuda.org"
      ];
      trusted-substituters = [
        "https://cache.iog.io"
        "https://nix-community.cachix.org"
        "https://cache.nixos-cuda.org"
      ];
      trusted-public-keys = [
        "cache.iog.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };
    # The system is built from npins (nix-conf/system.nix), not channels.
    channel.enable = false;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
    # Point <nixpkgs> (NIX_PATH) and the nixpkgs flake registry entry at
    # the pinned nixpkgs the system is built from. The store path must be
    # named "source" (NixOS/nix#7075); npins' builtin fetchTarball names
    # it that way.
    flake.source = "${sources.nixpkgs}";
  };

  # Keep every npins pin in the system closure. Otherwise a GC (nh clean)
  # deletes the pin sources and the next eval downloads them again.
  # Pins overridden to a local checkout (NPINS_OVERRIDE_*) are not store
  # paths and are skipped.
  system.extraDependencies = lib.filter (lib.hasPrefix builtins.storeDir) (
    lib.mapAttrsToList (_: pin: toString pin.outPath) (sources { })
  );
}
