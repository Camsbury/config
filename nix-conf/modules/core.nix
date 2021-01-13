{ config, pkgs, lib, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-20.09.tar.gz}/nixos")
    ../overlays/core.nix
    ../packages/core.nix
    ../private.nix
    ./zsh.nix
    ./check-battery.nix
    ./dropbox.nix
    ./screen_lock.nix
    ./exwm.nix
  ];

  home-manager.useUserPackages = true;

  boot = {
    cleanTmpDir = true;
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
        useOSProber = true;
        version = 2;
      };
      efi.canTouchEfiVariables = true;
    };
  };

  environment = {
    variables = {
      EDITOR = "vim";
      HISTCONTROL = "ignorespace";
    };
  };

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      go-font
      noto-fonts
      powerline-fonts
      roboto-mono
      ubuntu_font_family
    ];
  };

  documentation.dev.enable = true;

  hardware = {
    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
    };
    bluetooth.enable = true;
  };

  console = {
    font = "Go Mono";
    useXkbConfig = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  networking = {
    # wireless.enable = true;
    networkmanager.enable = true;
  };

  nix = {
    binaryCaches = [
      "https://hydra.iohk.io"
      "https://hie-nix.cachix.org"
    ];
    trustedBinaryCaches = [
      "https://hydra.iohk.io"
      "https://hie-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      "hie-nix.cachix.org-1:EjBSHzF7VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
    ];
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixpkgs-unstable=${../utils/unstable.nix}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs = {
    bash.enableCompletion = true;
    gnupg.agent = { enable = true; enableSSHSupport = true; };
  };

  services = {
    lorri.enable = true;
    keybase.enable = true;
    trezord.enable = true;
    xserver = {
      autoRepeatDelay = 300;
      autoRepeatInterval = 15;
      enable = true;
      layout = "us";
      displayManager.lightdm.enable = true;
    };
  };

  sound.enable = true;

  system.stateVersion = "20.03";

  time.timeZone = "America/New_York";

  users = {
    mutableUsers = false;
    groups.docker = {};
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
}
