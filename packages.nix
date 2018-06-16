# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

let
  unstableTarball =
  fetchTarball
    https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
in {
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
      enablePepperFlash = true;
      enablePepperPDF = true;
    };

    packageOverrides = pkgs: {
      unstable = import unstableTarball {
        config = config.nixpkgs.config;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # Stable Packages
    ack
    ag
    autojump # need to make this work
    bear
    cargo
    carnix
    chromium
    conky # haven't used
    curl
    dmenu
    dropbox-cli # bad version, should PR or unstable
    dzen2 # what am I currently using this for
    exa
    fd
    firefox
    fzf # need to integrate
    gcc
    gdb
    geoclue2 # redshift geo, but doesn't work
    ghc
    git
    gitAndTools.hub
    gnumake
    gnutls
    haskellPackages.Cabal_2_2_0_0
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    haskellPackages.xmonad-extras
    htop
    irony-server
    libnotify
    man-pages
    nix-repl
    notify-osd # to upgrade to zenity
    nox
    oh-my-zsh
    openssh
    peek
    python3
    redshift
    ripgrep
    shellcheck
    spotify # non-free
    steam # non-free
    sqlite
    tldr
    truecrypt
    udisks # manage drives
    unzip
    valgrind
    vim
    vlc
    weechat
    wget
    xbindkeys
    xclip # copy paste stuff
    xorg.xbacklight
    xorg.xmodmap
    zsh
  ] ++ [
    # Unstable Packages
    unstable.bat
  ] ++ [
    # Custom Packages
    (import ./emacs.nix { inherit pkgs; })
  ];
}
