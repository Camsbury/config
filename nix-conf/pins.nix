let
  # nixos channel pinned to 24.05 - https://github.com/NixOS/nixpkgs/archive/759537f0.tar.gz
  last-unstable = {
    rev = "eabe8d3eface";
    hash = "sha256-OTeQA+F8d/Evad33JMfuXC89VMetQbsU4qcaePchGr4=";
  };
  unstable = {
    rev = "4f3154007932";
    hash = "sha256-AHTKbJ9ffR7Nx+XcR2XP0AYLI4OlUh2IGh4SAkdG5Ig=";
  };
  chromium = {
    rev = "4f3154007932";
    hash = "sha256-AHTKbJ9ffR7Nx+XcR2XP0AYLI4OlUh2IGh4SAkdG5Ig=";
  };
in
  {
    inherit unstable;

    hardware = {
      # NOTE: from nixos-hardware repo
      rev = "72d53d51704295f1645d20384cd13aecc182f624";
      hash = "sha256-5VSB63UE/O191cuZiGHbCJ9ipc7cGKB8cHp0cfusuyo=";
    };

    inherit chromium;
    chrome = chromium;
    brave = chromium;

    cuda = unstable;
    vbox = unstable;

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
