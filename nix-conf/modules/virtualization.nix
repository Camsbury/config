{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    virt-viewer
  ];
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
      ovmf = {
        enable = true;
        packages = [(pkgs.OVMF.override {
          secureBoot = true;
          tpmSupport = true;
        }).fd];
      };
    };
  };
  programs.virt-manager.enable = true;
  users.users.default.extraGroups = [ "libvirtd" ];

  # Pick the right module for your CPU:
  boot.kernelModules = [ "kvm" "kvm_intel" ];

  # Optional: UEFI firmware and TPM for modern guests
}
