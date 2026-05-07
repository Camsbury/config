let
  # nixos channel pinned to 25.11 - https://github.com/NixOS/nixpkgs/archive/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f.tar.gz
  last-unstable = {
    rev = "08f22084e608";
    hash = "sha256-XE/lFNhz5lsriMm/yjXkvSZz5DfvKJLUjsS6pP8EC50=";
  };
  unstable = {
    rev = "cadcc8de2476";
    hash = "sha256-QJiih52NU+nm7XQWCj+K8SwUdIEayDQ1FQgjkYISt4I=";
  };
  hardware = {
    rev = "537286c3c59b40311e5418a180b38034661d2536";
    hash = "sha256-cgXDFrplNGs7bCVzXhRofjD8oJYqqXGcmUzXjHmip6Y=";
  };

  inherit (import <nixpkgs> {}) fetchFromGitHub;
  fetchPackages = hashes: fetchFromGitHub (
    {
      owner = "NixOS";
      repo  = "nixpkgs";
    } // hashes
  );
  fetchHardware = hashes: fetchFromGitHub (
    {
      owner = "NixOS";
      repo  = "nixos-hardware";
    } // hashes
  );
in
{
  cuda = fetchPackages last-unstable;
  discord = fetchPackages unstable;
  hardware = fetchHardware hardware;
  spotify = fetchPackages unstable;
  unstable = fetchPackages unstable;
  vbox = fetchPackages unstable;
  wine = fetchPackages unstable;
}
