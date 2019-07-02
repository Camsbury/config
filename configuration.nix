# Declarative Config for NixOS

{ config, pkgs, ... }:

let
  machine = import ./machine.nix;
  opSession = import ./op.nix;
  unstableTarball = import ./unstable.nix;
    unstable = import unstableTarball { config = {allowUnfree = true;}; };
in
  {
    imports =
      [ # Modular NixOS Configuration
        /etc/nixos/hardware-configuration.nix
        ./cachix.nix
        ./encryption.nix
        ./fonts.nix
        ./networking.nix
        ./ui.nix
        ./users.nix
      ];

    nixpkgs.config = {
      allowUnfree = true;
    };

    nixpkgs.overlays = import ./overlays.nix;

    nix.nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos/nixpkgs"
      "nixpkgs-unstable=${unstableTarball}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    security.wrappers.slock.source = "${pkgs.slock.out}/bin/slock";

    environment.systemPackages = import ./packages {inherit pkgs;};

    virtualisation.docker.enable = true;
    virtualisation.docker.enableOnBoot = true;

    # Use the systemd-boot EFI boot loader.
    # boot.loader.systemd-boot.enable = true;
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "nodev";
    boot.loader.grub.useOSProber = true;
    boot.loader.grub.efiSupport = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.kernelPackages = pkgs.linuxPackages_latest;

    # Select internationalisation properties.
    i18n = {
      consoleFont = "Roboto Mono";
      consoleUseXkbConfig = true;
      defaultLocale = "en_US.UTF-8";
    };

    # Set your time zone.
    time.timeZone = "America/New_York";

    environment.variables = {
      OH_MY_ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      FZF = [ "${pkgs.fzf}/share/fzf" ];
      AUTOJUMP = [ "${pkgs.autojump}/share/autojump" ];
      EDITOR = "vim";
      HISTCONTROL = "ignorespace";
    } // opSession;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.bash.enableCompletion = true;
    # programs.mtr.enable = true;
    programs.gnupg.agent = { enable = true; enableSSHSupport = true; };

    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;

    # Enable CUPS to print documents.
    # services.printing.enable = true;

    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio = {
      enable = true;
      # For Steam
      support32Bit = true;
      # For bluetooth
      package = pkgs.pulseaudioFull;
    };

    hardware.bluetooth.enable = true;

    # For Steam
    hardware.opengl.driSupport32Bit = true;

    # Suspend with power button
    services.logind.extraConfig = "HandlePowerKey=ignore";


    # Don't change without guidance
    system.stateVersion = "19.03";
  } // (
    if machine.laptop
    then {
      services = {
        xserver.libinput = {
          enable = true;
          naturalScrolling = true;
          tapping = false;
        };
        upower.enable = true;
        # cron = {
        #   enable = true;
        #   systemCronJobs = {
        #     "***** checkpower"
        #   };
        # };
      };
    } else {}
  ) // (
    if machine.nvidia
    then {
      #set up nvidia drivers
      services.xserver.videoDrivers = [ "nvidia" ];
    } else {}
  )
