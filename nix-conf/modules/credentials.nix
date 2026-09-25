{ pkgs, ... }:

# Keys and secrets: GPG, SSH, pass, keybase, and the TLS tooling.
{
  environment = {
    variables = {
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
      pass
      pinentry-gnome3
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

  services.keybase.enable = true;
}
