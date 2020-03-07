{ config, pkgs, ... }:

{
  boot.loader.grub.efiInstallAsRemovable = true;
}
