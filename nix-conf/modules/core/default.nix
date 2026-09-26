# core: boot; nix; networking and VPN clients; locale and time; disks and
# volumes, including tools that inspect or encrypt them; accounts; secrets
# and keys; health monitoring
#
# The cluster every machine imports: it brings in the machine's hardware
# configuration, the overlays, the other clusters, and holds the base
# system subjects as sections. A setting belongs here only when its
# subject is on the list above.
{
  config,
  lib,
  pkgs,
  sources,
  ...
}:

let
  sharePath = "${config.users.users.default.home}/Dropbox/lxndr";
in
{
  imports = [
    /etc/nixos/hardware-configuration.nix
    "${sources.home-manager}/nixos"
    ../../overlays/core.nix
    ../../private.nix

    ./nix.nix
    ./observability.nix
    ../hardware/disks.nix

    # The other clusters. Each is a directory whose default.nix is its
    # entry module; opt-in files inside them are a machine's to import.
    ../apps
    ../desktop
    ../dev
    ../shell
  ];

  config = lib.mkMerge [
    # --- accounts ---
    {
      users = {
        mutableUsers = false;
        users.default = {
          home = "/home/${toString config.users.users.default.name}";
          extraGroups = [
            "wheel"
            "networkmanager"
          ];
          isNormalUser = true;
        };
      };

      home-manager = {
        useUserPackages = true;
        users.default = import ../home.nix;
      };

      environment.variables = {
        USER_EMAIL = "camsbury7@gmail.com";
        USER_GPG_ID = "D3F6CEF58C6E0F38";
        # Books, notes, summaries, and sounds shared across machines.
        SHAREPATH = sharePath;
      };
    }

    # --- boot ---
    # Boot and shutdown: the boot loader, what a boot resets, and how long
    # shutdown waits for services.
    {
      boot = {
        loader = {
          grub = {
            device = "nodev";
            enable = true;
            efiSupport = true;
          };
          efi.canTouchEfiVariables = true;
        };
        tmp.cleanOnBoot = true;
      };

      # Every root here is on LUKS, so unlocking can take as long as it
      # takes: no device timeout on /. Was repeated in all three machine
      # files with this exact value.
      fileSystems."/".options = [ "x-systemd.device-timeout=infinity" ];

      # Bounds how long systemd waits for a unit to stop, so a hung service
      # cannot stall a shutdown or reboot for the default 90 s.
      systemd.settings.Manager.DefaultTimeoutStopSec = 10;
    }

    # --- disks and volumes ---
    # Mounting removable media, encrypted volumes, and disk usage.
    {
      services.udisks2.enable = true;

      environment.systemPackages = with pkgs; [
        baobab
        dua
        dust
        veracrypt
      ];
    }

    # --- locale and time ---
    {
      i18n.defaultLocale = "en_US.UTF-8";
      time.timeZone = "America/New_York";
    }

    # --- networking and VPN clients ---
    # NetworkManager, the VPN clients, and the firewall policy they need.
    {
      networking = {
        networkmanager.enable = true;
        firewall.checkReversePath = false;
      };

      environment.systemPackages = with pkgs; [
        openvpn
        proton-vpn
      ];

      services.netbird.clients.wt0 = {
        port = 51821;
        ui.enable = false; # or true if you want the tray icon
        openFirewall = true;
        openInternalFirewall = true;
      };
    }

    # --- secrets and keys ---
    # GPG, SSH, pass, keybase, and the TLS tooling.
    {
      environment = {
        variables = {
          SSH_ASKPASS_REQUIRE = "force";
        };
        sessionVariables = {
          PASSWORD_STORE_DIR = "${sharePath}/password-store";
        };
        systemPackages = with pkgs; [
          gnupg
          gnutls
          keybase
          keybase-gui
          keychain
          openssh
          openssl
          pass
          pinentry-gnome3
        ];
      };

      programs = {
        gnupg.agent = {
          enable = true;
          enableSSHSupport = true;
          pinentryPackage = pkgs.pinentry-gnome3;
        };
        ssh.startAgent = false;
      };

      services.keybase.enable = true;
    }
  ];
}
