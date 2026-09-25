{ pkgs, ... }:

# The keyboard layout and key repeat, in X and on the console, plus the
# tools that switch and remap it. Machines add layout variants on top
# (foreign.nix, non-ergodox.nix).
{
  services.xserver = {
    autoRepeatDelay = 300;
    autoRepeatInterval = 15;
    xkb.layout = "us";
  };

  # The console follows the X layout.
  console.useXkbConfig = true;

  environment.systemPackages = with pkgs; [
    xkb-switch
    xmodmap
  ];
}
