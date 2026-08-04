{ config, pkgs, lib, ... }:

{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.80";
      sha256_64bit = "sha256-PVTIP+B/01c/8M66hXTAYTLg9T2Hy9u1gq43K7TF1Hg=";
      openSha256 = "sha256-nonwYYPItHeMC/5Ox/TlWhjiddMPu4PLqNhgIg+bfW8=";
      settingsSha256 = "sha256-AtzYTz7kbmj3vxmBQTC0eAjM3b2I259y1tdxq90n9YU=";
      persistencedSha256 = lib.fakeSha256;
    };
    open = true;
    modesetting.enable = true;
  };

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # services.ollama.package = pkgs.ollama-cuda;

}
