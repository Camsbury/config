{ config, pkgs, ... }:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    <home-manager/nixos>
    ../overlays/core.nix
    ../packages/core.nix
    ../private.nix
    ./zsh.nix
    ./check-battery.nix
  ];

  home-manager.useUserPackages = true;

  boot = {
    cleanTmpDir = true;
    loader = {
      grub = {
        device = "nodev";
        enable = true;
        efiSupport = true;
        # useOSProber = true;
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
    enableFontDir = true;
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

  # networking.wireless.enable = true;
  networking = {
    networkmanager.enable = true;
  };

  nix = {
    binaryCaches = [
      "https://cache.nixos.org/"
      "https://hie-nix.cachix.org"
    ];
    binaryCachePublicKeys = [
      "hie-nix.cachix.org-1:EjBSHzF7VmDnzqlldGXbi0RM3HdjfTU3yDRi9Pd0jTY="
    ];
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixpkgs-unstable=${../utils/unstable.nix}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  nixpkgs.config = {
    allowUnfree = true;
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

      displayManager = {
        lightdm.enable = true;
        defaultSession = "none+xmonad";
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
      };
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
