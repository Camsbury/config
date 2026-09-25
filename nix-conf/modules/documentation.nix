{ config, lib, ... }:

{
  documentation.dev.enable = true;

  # Publish the NixOS option docs at a stable path, so tools can read
  # option names, types, and descriptions without evaluating the system.
  # The configuration.nix(5) man page is built from the same file, so this
  # adds no build. The manual exists only while NixOS docs are enabled.
  environment.etc."nixos/options.json" = lib.mkIf config.documentation.nixos.enable {
    source = "${config.system.build.manual.optionsJSON}/share/doc/nixos/options.json";
  };
}
