{ config, pkgs, ... }:

{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  programs.ssh.startAgent = false;

  services.keybase.enable = true;

  environment.variables = {
    USER_GPG_ID = "D3F6CEF58C6E0F38";
    SSH_ASKPASS_REQUIRE = "force";
  };
  environment.systemPackages = with pkgs; [
    gnupg
    gnutls
    keybase
    keybase-gui
    keychain
    openssh
    openssl
    openvpn
    pass
    pinentry-gnome3
    protonvpn-gui
    veracrypt
  ];

  networking.firewall.checkReversePath = false;

  security.sudo.extraRules = [{
    users = ["ALL"];
    commands = [
      { # maybe set this more intelligently
        command = "/usr/bin/env tee /sys/class/backlight/intel_backlight/brightness";
        options = ["NOPASSWD"];
      }
      {
        command = "/usr/bin/env systemctl restart display-manager.service";
        options = ["NOPASSWD"];
      }
    ];
  }];
}
