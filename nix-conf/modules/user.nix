{
  config,
  pkgs,
  lib,
  sources,
  ...
}:

{
  imports = [ (import "${sources.home-manager}/nixos") ];

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

  environment.variables = {
    USER_EMAIL = "camsbury7@gmail.com";
    USER_GPG_ID = "D3F6CEF58C6E0F38";
    # Books, notes, summaries, and sounds shared across machines.
    SHAREPATH = "/home/${toString config.users.users.default.name}/Dropbox/lxndr";
  };

  nix.settings.trusted-users = [
    "root"
    "${toString config.users.users.default.name}"
  ];
}
