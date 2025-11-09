{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    pavucontrol
    alsa-utils
  ];

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    extraConfig.pipewire = {
      "99-disable-bell" = {
        "context.properties"= {
          "module.x11.bell" = false;
        };
      };
    };
    pulse.enable = true;

    wireplumber = {
      enable = true;
      extraConfig = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [ "a2dp_sink" "a2dp_source" ];
        };
      };
    };
  };
}
