# disks: per-class disk policy, so `core` imports it on every machine.
# Every setting here names the class of device it acts on, so it is right
# on any disk mix: a rule for rotational disks matches nothing on a machine
# with none.
{
  config,
  pkgs,
  sources,
  ...
}:

{
  # services.fstrim.enable, from nixos-hardware.
  imports = [
    "${sources.nixos-hardware}/common/pc/ssd"
  ];

  # Per-class I/O scheduler
  # NVMe → none (don't let bfq add latency to fast queues)
  # HDD → bfq (fairness/interactivity on seeks)
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme[0-9]*n[0-9]*", ATTR{queue/scheduler}="none"
    ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
  '';
}
