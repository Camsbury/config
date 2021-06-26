{ config, pkgs, ... }:

{
  imports = [
    ./docker.nix
  ];
  environment.systemPackages = with pkgs; [
    babashka
    binutils
    (emacsPackagesNg.emacsWithPackages (import ../packages/emacs.nix))
    entr
    direnv
    gdb
    git
    gitAndTools.git-extras
    gitAndTools.hub
    glibc
    gnumake
    google-cloud-sdk
    kubectl
    loc
    nixfmt
    update-nix-fetchgit
    nodePackages.prettier
    patchelf # patch dynamic libs/bins
    postgresql_11
    python3
    shellcheck
    sloccount
    sqlite
  ];
  services.lorri.enable = true;
}
