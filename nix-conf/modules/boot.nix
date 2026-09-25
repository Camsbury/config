{ ... }:

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

  # Bounds how long systemd waits for a unit to stop, so a hung service
  # cannot stall a shutdown or reboot for the default 90 s.
  systemd.settings.Manager.DefaultTimeoutStopSec = 10;
}
