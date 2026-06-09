{ config, pkgs, lib, ... }:

{
  imports = [
    ../modules/core.nix

    # hardware
    ../modules/intel.nix
    ../modules/rtx-5070-ti.nix
    ../modules/ssd.nix
    ../modules/slimblade.nix

    #functionality
    ../modules/android.nix
    ../modules/art.nix
    ../modules/bluetooth.nix
    ../modules/crypto.nix
    ../modules/cuda.nix
    ../modules/gaming.nix
    ../modules/music.nix
    ../modules/influxdb.nix
    ../modules/rgb.nix

    ../modules/gen-ai.nix
    ../modules/email.nix
    ../modules/virtualization.nix
    ../modules/razer.nix
    ../modules/foreign.nix
    ../modules/printing.nix
    ../modules/svalboard.nix
  ];

  # Make JVM stuff smoother
  systemd.tmpfiles.rules = [
    "w /sys/kernel/mm/transparent_hugepage/enabled       - - - - madvise"
    "w /sys/kernel/mm/transparent_hugepage/shmem_enabled - - - - advise"
    "w /sys/kernel/mm/transparent_hugepage/defrag        - - - - defer"
  ];

  # Just in case my memory blows up
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;
    options = [ "discard" ];
  }];


  services = {
    # Persist the monitor selection
    xserver = {
      screenSection = ''
        Option "CustomEDID" "DP-0:/etc/nixos/monitor.edid"
        Option "UseEDID" "true"
        Option "UseEDIDFreqs" "true"
        Option "ModeValidation" "AllowNonEdidModes"
        Option "MetaModes" "DPY-1: 3840x2160_240 +0+0"
      '';
      xrandrHeads = [
        {
          output = "DP-0";
          primary = true;
        }
      ];
      dpi = 139;
      displayManager.sessionCommands = ''
        echo "Xft.dpi: 139" | ${pkgs.xrdb}/bin/xrdb -merge
      '';
    };

    # machine specific dl dir for transmission
    transmission.settings.download-dir = "/mnt/hdd16t/transmission-downloads";

    # Per-class I/O scheduler
    # NVMe → none (don't let bfq add latency to fast queues)
    # HDD → bfq (fairness/interactivity on seeks)
    udev.extraRules = ''
      ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
      ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
    '';
  };

  hardware = {
    cpu.intel.updateMicrocode = true;
    enableRedistributableFirmware = true;
  };

  boot = {
    # kernelPackages = pkgs.linuxPackages_latest;
    kernel.sysctl = {
      "vm.dirty_background_bytes" = 268435456;  # start flushing early
      "vm.dirty_bytes"            = 1073741824; # ceiling before throttling
      "kernel.nmi_watchdog"       = 0;
    };
    # if you ever need to test memory after changing settings
    # loader.grub.memtest86.enable = true;
    initrd = {
      systemd.services = {
        "systemd-cryptsetup@cryptedStore"   = {
          overrideStrategy = "asDropin";
          after = [ "systemd-cryptsetup@crypted.service" ];
        };
        "systemd-cryptsetup@cryptedHDD16T"  = {
          overrideStrategy = "asDropin";
          after = [ "systemd-cryptsetup@crypted.service" ];
        };
        "systemd-cryptsetup@cryptedSSD500G" = {
          overrideStrategy = "asDropin";
          after = [ "systemd-cryptsetup@crypted.service" ];
        };
      };
      luks.devices = {
        crypted.device = "/dev/disk/by-uuid/a5f95eb4-a033-40c9-81a1-4ae489adfc7c";
        cryptedStore.device = "/dev/disk/by-uuid/77a45769-1398-44bd-a7a4-ebb05bfad2f6";
        cryptedSSD500G.device = "/dev/disk/by-uuid/88df2045-baed-444d-ad6f-3832d841ee61";
        cryptedHDD16T.device = "/dev/disk/by-uuid/720ce7b5-e3aa-4b7e-a079-e06c9c3e42a0";
      };
    };
  };

  fileSystems."/".options = [ "x-systemd.device-timeout=infinity" ];

  networking.hostName = "poseidon";
  users.users.default.name = "camsbury";

  system.stateVersion = "24.11";
}
