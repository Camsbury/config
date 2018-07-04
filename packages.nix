# System packages contains all of the system-wide packages installed on my NixOS machines.

{ config, pkgs, ... }:

let
  unstableTarball =
  fetchTarball
    https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;

  machine = (import ./machine.nix);
in {
  nixpkgs.config = {
    allowUnfree = true;

    chromium = {
    #   enablePepperFlash = true;
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
    autojump
    bear
    cabal-install
    cabal2nix
    cargo
    carnix
    chromium
    curl
    dmenu
    # dropbox-cli # bad version, should PR or unstable
    exa
    fd
    firefox
    fzf
    gcc
    gdb
    ghc
    git
    gitAndTools.hub
    gnumake
    gnutls
    haskellPackages.apply-refact
    haskellPackages.Cabal_2_2_0_0
    haskellPackages.hlint
    haskellPackages.xmonad
    haskellPackages.xmonad-contrib
    haskellPackages.xmonad-extras
    htop
    irony-server
    libnotify
    man-pages
    notify-osd # to upgrade to zenity
    nox
    oh-my-zsh
    openssh
    peek
    python3
    redshift
    ripgrep
    shellcheck
    slock
    # spotify # non-free
    sqlite
    teensy-loader-cli
    tldr
    tree
    udisks # manage drives
    unzip
    valgrind
    veracrypt
    vim
    vlc
    weechat
    wget
    xbindkeys
    xclip # copy paste stuff
    xorg.xbacklight
    xorg.xmodmap
    xss-lock
    zsh
  ] ++ [
    # Unstable Packages
    unstable.bat
    unstable.dropbox-cli
    unstable.spotify # non-free
  ] ++ [
    # Custom Packages
    # (import ./emacs.nix { inherit pkgs; })
    (import ./emacs.nix { pkgs = unstable; })
  ] ++ (    # Machine Specific
  if machine.gaming
  then
  [ steam #non-free
  ] else []
  );

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";
}
