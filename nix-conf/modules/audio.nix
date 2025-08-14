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
      extraConfig.bluetoothEnhancements = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [ "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
        };
      };
    };
  };

}
