{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Blind monitor recovery, bound to F17 below. It wakes the panel (DPMS on,
  # a harmless no-op when already awake), then retrains the DisplayPort link
  # by modesetting DP-0 through 4K 120 Hz and back to 240 Hz. `+dpms` comes
  # first because the X server answers `dpms force on` with BadMatch while
  # DPMS is disabled, so the wake step would silently do nothing after any
  # `xset -dpms`. Mirrors `ck/fix-monitor-blackouts`
  # (emacs-conf/config/desktop/commands/system.el), but triggerhappy
  # (modules/media_keys.nix) runs it BELOW the i3lock X keyboard grab, so it
  # recovers a black overnight wake even while the screen is locked.
  #
  # xset and xrandr talk to X, so the script names the running server and
  # the user's auth cookie explicitly: triggerhappy runs as the user but
  # with a bare environment, and HOME is not reliable there, so the home
  # path is resolved at eval time.
  username = toString config.users.users.default.name;
  xset = "${pkgs.xset}/bin/xset";
  xrandr = "${pkgs.xrandr}/bin/xrandr";
  monitorRecover = pkgs.writeShellScript "monitor-recover" ''
    export DISPLAY=:0
    export XAUTHORITY=/home/${username}/.Xauthority
    ${xset} +dpms
    ${xset} dpms force on
    ${xrandr} --output DP-0 --mode 3840x2160 --rate 119.88
    ${pkgs.coreutils}/bin/sleep 1
    ${xrandr} --output DP-0 --mode 3840x2160 --rate 240.02
  '';
in
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
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
      options = [ "discard" ];
    }
  ];

  services = {
    # Persist the monitor selection. The EDID is pinned from a repo-tracked
    # dump (nix-conf/machines/poseidon.edid) baked into the nix store, so the
    # pin cannot silently dangle like the old /etc/nixos/monitor.edid symlink
    # did. Re-dump after a monitor swap: cat /sys/class/drm/card*-DP-*/edid
    # (the connected one) > poseidon.edid
    #
    # ConnectedMonitor forces the driver to always report DP-0 as connected
    # and ignore hot-plug-detect. Without it, physically powering the monitor
    # OFF asserts HPD-low, the driver disconnects the sole output, and X is
    # left with no display ("display not found"; only a TTY works). CustomEDID
    # is what makes this safe: a forced-connected output cannot read live EDID
    # from a powered-off panel, so it falls back to the pinned dump for modes.
    xserver = {
      screenSection = ''
        Option "ConnectedMonitor" "DP-0"
        Option "CustomEDID" "DP-0:${./poseidon.edid}"
        Option "UseEDID" "true"
        Option "UseEDIDFreqs" "true"
        Option "ModeValidation" "AllowNonEdidModes"
        Option "MetaModes" "DPY-1: 3840x2160_240 +0+0 {AllowGSYNC=Off, AllowGSYNCCompatible=Off}"
      '';
      xrandrHeads = [
        {
          output = "DP-0";
          primary = true;
        }
      ];
      dpi = 139;
      displayManager.sessionCommands = ''
        echo "Xft.dpi: ${toString config.services.xserver.dpi}" | ${pkgs.xrdb}/bin/xrdb -merge
        ${config.hardware.nvidia.package.settings}/bin/nvidia-settings \
          -a AllowVRR=0
      '';
    };

    # Monitor recovery (F17, mapped in QMK). Merges with the media-key
    # bindings in modules/media_keys.nix.
    triggerhappy.bindings = [
      {
        keys = [ "F17" ];
        cmd = "${monitorRecover}";
      }
    ];

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
      "vm.dirty_background_bytes" = 268435456; # start flushing early
      "vm.dirty_bytes" = 1073741824; # ceiling before throttling
      "kernel.nmi_watchdog" = 0;
    };
    # if you ever need to test memory after changing settings
    # loader.grub.memtest86.enable = true;
    initrd = {
      systemd.services = {
        "systemd-cryptsetup@cryptedStore" = {
          overrideStrategy = "asDropin";
          after = [ "systemd-cryptsetup@crypted.service" ];
        };
        "systemd-cryptsetup@cryptedHDD16T" = {
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
