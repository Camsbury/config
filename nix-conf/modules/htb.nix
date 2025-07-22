{ config, pkgs, ... }:

let
  vboxPkgs = import (import ../pins.nix).vbox {
    config = {
      allowUnfree = true;
    };
  };
in
{
  nixpkgs.overlays = [
    (self: super: {
      virtualbox = vboxPkgs.virtualbox;
      virtualboxExtpack = vboxPkgs.virtualboxExtpack;
    })
  ];


  users.extraGroups.vboxusers.members = [
    "${toString config.users.users.default.name}"
  ];
  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.enableExtensionPack = true;
}
