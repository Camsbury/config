{ config, pkgs, ... }:

# peon-ping: Warcraft-voice audio notifications for ECA chats.
#
# This module only installs the `peon` binary. The rest of the setup lives
# outside this repo and is imperative (harmless if missing: no packs just
# means silence, nothing breaks):
#
#   1. Sound packs + peon config live in ~/.openpeon (untracked local state).
#      The nix store path is read-only, so peon falls back there. Install and
#      pick a pack once per machine:
#          peon packs list --registry        # browse available packs
#          peon packs use --install <name>   # download + activate a pack
#          peon preview --list               # sanity-check categories/sounds
#
#   2. ECA wiring (in the Dropbox-synced eca config, not nix):
#          ~/.config/eca/config.json         # 4 hooks -> the adapter below
#          ~/.config/eca/hooks/peon-ping/eca-adapter.sh
#      The adapter maps ECA hook_type -> Claude Code event names -> `peon`.
#      Add a new event by extending its type_map dict.
#
# The flake ref below is intentionally unpinned (floats outside flake.lock);
# `peon update` refreshes packs independently.
let
  peon-flake = builtins.getFlake "github:PeonPing/peon-ping";
  peon-ping = peon-flake.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  environment = {
    # variables = {
    #   OLLAMA_MODELS = "/media/camsbury/ollama-models";
    # };
    systemPackages = with pkgs; [
      # gollama
      lmstudio
      peon-ping
    ];
  };

  # services.ollama = {
  #   enable = true;
  # };
}
