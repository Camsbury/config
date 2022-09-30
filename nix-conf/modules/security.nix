{ config, pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  services.keybase.enable = true;

  environment.systemPackages = with pkgs; [
    gnupg
    gnutls
    keybase
    keybase-gui
    keychain
    openssh
    openssl
    openvpn
    veracrypt
  ];

  security.sudo.extraRules = [{
    users = ["ALL"];
    commands = [{
      # maybe set this more intelligently
      command = "/usr/bin/env tee /sys/class/backlight/intel_backlight/brightness";
      options = ["NOPASSWD"];
    }];
  }];
}
