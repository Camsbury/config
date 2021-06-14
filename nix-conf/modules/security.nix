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
}
