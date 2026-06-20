{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    /etc/nixos/hardware-configuration.nix
    ../overlays/core.nix
    ../private.nix

    ./audio.nix
    ./apps.nix
    ./boot.nix
    ./cmacs.nix
    ./desktop.nix
    ./dev.nix
    ./display.nix
    ./dropbox.nix
    ./search.nix
    ./security.nix
    ./shell.nix
    ./system.nix
    ./user.nix
    ./utils.nix
  ];

  environment.variables = {
    USER_EMAIL = "camsbury7@gmail.com";
    SHAREPATH = "/home/${toString config.users.users.default.name}/Dropbox/lxndr";
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = 10;

  # Needed for Home Manager to set GTK themes
  programs.dconf.enable = true;
  environment = {
    systemPackages = with pkgs; [
      gsettings-desktop-schemas
      gtk3
    ];
    sessionVariables = {
      XDG_DATA_DIRS = [
        "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}"
        "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}"
      ];
    };
  };
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # clean /tmp
  boot.tmp.cleanOnBoot = true;

  networking.networkmanager.enable = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      substituters = [
        "https://cache.iog.io"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-substituters = [
        "https://cache.iog.io"
        "https://nix-community.cachix.org"
        "https://cuda-maintainers.cachix.org"
      ];
      trusted-public-keys = [
        "cache.iog.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
}
