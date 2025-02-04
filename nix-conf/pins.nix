let
  # nixos channel pinned to 24.11 - https://github.com/NixOS/nixpkgs/archive/f6687779bf4c396250831aa5a32cbfeb85bb07a3.tar.gz
  # nixos channel was pinned to 24.05 - https://github.com/NixOS/nixpkgs/archive/759537f0.tar.gz
  last-unstable = {
    rev = "4f3154007932";
    hash = "sha256-AHTKbJ9ffR7Nx+XcR2XP0AYLI4OlUh2IGh4SAkdG5Ig=";
  };
  unstable = {
    rev = "102a39bfee44";
    hash = "sha256-Q4vhtbLYWBUnjWD4iQb003Lt+N5PuURDad1BngGKdUs=";
  };
  chromium = {
    # rev = "4f3154007932";
    # hash = "sha256-AHTKbJ9ffR7Nx+XcR2XP0AYLI4OlUh2IGh4SAkdG5Ig=";
    rev = "102a39bfee44";
    hash = "sha256-Q4vhtbLYWBUnjWD4iQb003Lt+N5PuURDad1BngGKdUs=";
  };
in
  {
    inherit unstable;

    hardware = {
      # NOTE: from nixos-hardware repo
      # rev = "72d53d51704295f1645d20384cd13aecc182f624";
      rev = "537286c3c59b40311e5418a180b38034661d2536";
      hash = "sha256-cgXDFrplNGs7bCVzXhRofjD8oJYqqXGcmUzXjHmip6Y=";
    };

    inherit chromium;
    chrome = chromium;
    brave = chromium;

    cuda = unstable;
    vbox = last-unstable;

    wine = unstable;
    # wine = {
    #   rev = "b50a77c03d64";
    #   hash = "sha256-zJaF0RkdIPbh8LTmnpW/E7tZYpqIE+MePzlWwUNob4c=";
    # };

    discord = unstable;
    # discord = {
    #   rev = "a518c771485";
    #   hash = "sha256-oz757DnJ1ITvwyTovuwG3l9cX6j9j6/DH9eH+cXFJmc=";
    # };

  }
