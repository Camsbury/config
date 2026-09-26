{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# It puts the compose key on Menu, for typing characters a plain us layout
# has no key for. `services.xserver.xkb.options` is `types.commas`, so this
# concatenates with the options a keyboard module sets rather than
# conflicting with them.
{
  services.xserver = {
    xkb.options = "compose:menu";
  };
}
