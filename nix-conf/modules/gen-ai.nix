{ config, pkgs, ... }:

{
  environment = {
    variables = {
      OLLAMA_MODELS = "/media/camsbury/ollama-models";
    };
    systemPackages = with pkgs; [
      gollama
      lmstudio
      (builtins.getFlake "github:PeonPing/peon-ping").packages.${pkgs.system}.default
    ];
  };

  services.ollama = {
    enable = true;
  };
}
