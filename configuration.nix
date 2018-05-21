# Declarative Config for NixOS

{ config, pkgs, ... }:

let
  machine = (import ./machine.nix);
in
  {
    imports =
      [ # Modular NixOS Configuration
        /etc/nixos/hardware-configuration.nix
        ./networking.nix
        ./system-packages.nix
        ./ui.nix
        ./users.nix
      ];
  
    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  
    # Select internationalisation properties.
    i18n = {
      consoleFont = "Lat2-Terminus16";
      consoleKeyMap = "us";
      defaultLocale = "en_US.UTF-8";
    };
  
    # Set your time zone.
    time.timeZone = "America/New_York";
  
    # List packages installed in system profile. To search, run:
    # $ nix search wget
    environment.variables = {
      OH_MY_ZSH = [ "${pkgs.oh-my-zsh}/share/oh-my-zsh" ];
      EDITOR = "vim";
    };
  
    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.bash.enableCompletion = true;
    # programs.mtr.enable = true;
    # programs.gnupg.agent = { enable = true; enableSSHSupport = true; };
  
    # Enable the OpenSSH daemon.
    # services.openssh.enable = true;
  
    # Enable CUPS to print documents.
    # services.printing.enable = true;
  
    # Enable sound.
    sound.enable = true;
    hardware.pulseaudio.enable = true;

    # Allow unfree software (like nvidia drivers)
    nixpkgs.config.allowUnfree = true;

    # Don't change without guidance
    system.stateVersion = "18.03";
  } // (
    if machine.laptop
    then {
      # enable touchpad
      services.xserver.libinput.enable = true;
    } else {}
  ) // (
    if machine.nvidia
    then {
      #set up nvidia drivers
      services.xserver.videoDrivers = [ "nvidia"];
    } else {}
  )
