let
  # hash via
  # nix --extra-experimental-features nix-command store prefetch-file --unpack https://github.com/NixOS/nixpkgs/archive/<REV>.tar.gz
  unstable = {
    rev = "4100e830e085";
    hash = "sha256-NOF9NAREhxr50bbBfVcVOq+ArCMSoe8dP79Pk2uyARk=";
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
  cuda = fetchPackages unstable;
  discord = fetchPackages unstable;
  hardware = fetchHardware hardware;
  spotify = fetchPackages unstable;
  unstable = fetchPackages unstable;
  wine = fetchPackages unstable;
}
