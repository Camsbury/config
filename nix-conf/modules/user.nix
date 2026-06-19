{ config, pkgs, lib, home-manager-pkgs, ... }:

{
  imports = [ (import "${home-manager-pkgs}/nixos") ];

  users = {
    mutableUsers = false;
    users.default = {
      home = "/home/${toString config.users.users.default.name}";
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      isNormalUser = true;
    };
  };

  home-manager = {
    useUserPackages = true;
    users.default = import ../modules/home.nix;
  };

  nix.settings.trusted-users = [
    "root"
    "${toString config.users.users.default.name}"
  ];
}
