let
  # nixos channel pinned to 25.05 - https://github.com/NixOS/nixpkgs/archive/6c64dabd3aa85e0c02ef1cdcb6e1213de64baee3.tar.gz
  # nixos channel pinned to 24.11 - https://github.com/NixOS/nixpkgs/archive/f6687779bf4c396250831aa5a32cbfeb85bb07a3.tar.gz
  # nixos channel was pinned to 24.05 - https://github.com/NixOS/nixpkgs/archive/759537f0.tar.gz
  last-unstable = {
    rev = "102a39bfee44";
    hash = "sha256-Q4vhtbLYWBUnjWD4iQb003Lt+N5PuURDad1BngGKdUs=";
  };
  unstable = {
    rev = "08f22084e608";
    hash = "sha256-XE/lFNhz5lsriMm/yjXkvSZz5DfvKJLUjsS6pP8EC50=";
  };
  hardware = {
    # NOTE: from nixos-hardware repo
    rev = "537286c3c59b40311e5418a180b38034661d2536";
    hash = "sha256-cgXDFrplNGs7bCVzXhRofjD8oJYqqXGcmUzXjHmip6Y=";
  };

  inherit (import <nixpkgs> {}) fetchFromGitHub;
  fetchPackages = hashes: fetchFromGitHub ({
      owner = "NixOS";
      repo  = "nixpkgs";
    } // hashes
  );
in
  {
    cuda = fetchPackages unstable;
    discord = fetchPackages unstable;
    hardware = fetchPackages hardware;
    spotify = fetchPackages unstable;
    unstable = fetchPackages unstable;
    vbox = fetchPackages unstable;
    wine = fetchPackages unstable;
  }
