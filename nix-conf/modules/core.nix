{ config, pkgs, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../packages/core.nix
    ../overlays/core.nix
    ../private.nix
    ./zsh.nix
  ];

  boot = {
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
        useOSProber = true;
        version = 2;
      };
      # efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  environment = {
    variables = {
      EDITOR = "vim";
      HISTCONTROL = "ignorespace";
    };
  };

  fonts.fonts = with pkgs; [
    go-font
    noto-fonts
    roboto-mono
  ];

  hardware = {
    pulseaudio = {
      enable = true;
      support32Bit = true;
      package = pkgs.pulseaudioFull;
    };
    bluetooth.enable = true;
    opengl.driSupport32Bit = true;
  };

  i18n = {
    consoleFont = "Go Mono";
    consoleUseXkbConfig = true;
    defaultLocale = "en_US.UTF-8";
  };

  networking.networkmanager.enable = true;

  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
    "nixpkgs-unstable=${../utils/unstable.nix}"
    "nixos-config=/etc/nixos/configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  programs = {
    bash.enableCompletion = true;
    gnupg.agent = { enable = true; enableSSHSupport = true; };
  };

  security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";

  services = {
    lorri.enable = true;
    keybase.enable = true;
    logind.extraConfig = "HandlePowerKey=ignore";
    xserver = {
      enable = true;

      layout = "us";

      displayManager.slim = {
        enable = true;
        theme = pkgs.fetchurl {
          url = "https://github.com/edwtjo/nixos-black-theme/archive/v1.0.tar.gz";
          sha256 = "13bm7k3p6k7yq47nba08bn48cfv536k4ipnwwp1q1l2ydlp85r9d";
        };
      };

      autoRepeatDelay = 250;
      autoRepeatInterval = 20;


      windowManager = {
        xmonad = {
          enable = true;
          enableContribAndExtras = true;
          extraPackages = haskellPackages: [
            haskellPackages.xmonad
            haskellPackages.xmonad-contrib
            haskellPackages.xmonad-extras
          ];
        };
        default = "xmonad";
      };
    };
  };

  sound.enable = true;

  system.stateVersion = "19.09";

  time.timeZone = "America/New_York";

  users.mutableUsers = false;

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };
}
