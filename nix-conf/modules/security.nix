{ config, pkgs, ... }:

{


  environment = {
    variables = {
      USER_GPG_ID = "D3F6CEF58C6E0F38";
      SSH_ASKPASS_REQUIRE = "force";
    };
    systemPackages = with pkgs; [
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
      proton-vpn
      veracrypt
    ];
  };


  programs = {
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-gnome3;
    };
    ssh.startAgent = false;
  };

  services = {
    keybase.enable = true;
    netbird.clients.wt0 = {
      port = 51821;
      ui.enable = false;          # or true if you want the tray icon
      openFirewall = true;
      openInternalFirewall = true;
    };
  };

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
