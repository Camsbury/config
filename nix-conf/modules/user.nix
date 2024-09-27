{ config, pkgs, lib, ... }:

{
  imports = [
    (import "${builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-24.05.tar.gz}/nixos")
  ];

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
