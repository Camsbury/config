{ pkgs, ... }:

# Web browsers and the default one.
{
  environment = {
    variables = {
      BROWSER = "firefox";
    };
    systemPackages = with pkgs; [
      chromium
      firefox
      google-chrome # for certain features
    ];
  };
}
