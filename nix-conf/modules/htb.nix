{ config, pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  users.extraGroups.vboxusers.members = [
    "${toString config.users.users.default.name}"
  ];
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
