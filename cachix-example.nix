# Cachix Keys and Caches

{ config, pkgs, ... }:

{
  nix = {
    binaryCaches = [];
    binaryCachePublicKeys = [];
    trustedUsers = [];
  };
}
