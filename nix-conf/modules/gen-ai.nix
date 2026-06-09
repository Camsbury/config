{ config, pkgs, ... }:

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
