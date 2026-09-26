{
  config,
  pkgs,
  sources,
  ...
}:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Games: Steam, Wine, Lutris, and the controller plumbing they need.
# GPU monitoring is not here: it comes from the card's own module
# (../hardware/nvidia.nix). mesa and vulkan-tools stay, because they are
# the vendor-neutral graphics stack games link against.
let
  winePkgs = import sources.nixpkgs-unstable {
    config = {
      allowUnfree = true;
    };
    overlays = [
      (self: super: {
        openldap = super.openldap.overrideAttrs (_: {
          doCheck = false;
        });
      })
    ];
  };
in
{
  programs.steam.enable = true;

  # xdg = {
  #   portal = {
  #     enable = true;
  #     extraPortals = with pkgs; [
  #       xdg-desktop-portal-wlr
  #       xdg-desktop-portal-gtk
  #     ];
  #   };
  # };
  # services.flatpak.enable = true;

  hardware.steam-hardware.enable = true;

  environment = {
    systemPackages = with pkgs; [
      winePkgs.lutris
      joystickwake
      mesa
      sc-controller
      vulkan-tools
      (winePkgs.wineWow64Packages.full.override {
        wineRelease = "staging";
        mingwSupport = true;
      })
      # was used for wc3
      # (winePkgs.winetricks.override {
      #   wine = wineWowPackages.staging;
      # })
      winePkgs.winetricks
      xdg-user-dirs
      xgamma
    ];
  };

  # nixpkgs.overlays = [
  #   (self: super: {
  #     steam = steamPkgs.steam;
  #   })
  # ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 1000000;
  };

  systemd.services.joystickwake = {
    description = "joystickwake service";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.joystickwake}/bin/joystickwake";
    };
  };

}
