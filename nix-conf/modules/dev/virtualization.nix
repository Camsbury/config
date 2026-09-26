{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Running virtual machines you develop against: libvirtd, qemu, swtpm and
# virt-manager.
{
  # NOTE: run `virsh net-autostart default`
  environment = {
    variables = {
      LIBVIRT_DEFAULT_URI = "qemu:///system";
    };
    systemPackages = with pkgs; [
      virt-viewer
    ];
  };
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      # ovmf = {
      #   enable = true;
      #   packages = [(pkgs.OVMF.override {
      #     secureBoot = true;
      #     tpmSupport = true;
      #   }).fd];
      # };
    };
  };
  programs.virt-manager.enable = true;
  users.users.default.extraGroups = [ "libvirtd" ];

  # `kvm` is vendor-neutral, so it belongs with the VM tooling. The vendor
  # module beside it (`kvm_intel`, `kvm_amd`) is a fact about the CPU and
  # comes from the CPU's hardware module.
  boot.kernelModules = [
    "kvm"
  ];

  # Optional: UEFI firmware and TPM for modern guests
}
