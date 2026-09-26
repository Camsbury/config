{
  config,
  pkgs,
  sources,
  ...
}:

{
  imports = [
    "${sources.nixos-hardware}/common/cpu/intel/cpu-only.nix"
  ];

  # The Intel virtualization extension. This states what the part can do;
  # the installer's `hardware-configuration.nix` may already list it (as
  # `kvm-intel`) on a machine that has it, and the list merges, so the
  # module loads once either way. `kvm` itself is vendor-neutral and lives
  # in ../dev/virtualization.nix.
  boot.kernelModules = [ "kvm_intel" ];
}
