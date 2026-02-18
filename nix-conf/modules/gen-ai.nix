{ config, pkgs, ... }:

{
  environment = {
    variables = {
      OLLAMA_MODELS = "/media/monoid/ollama-models";
    };
    systemPackages = with pkgs; [
      gollama
      lmstudio
    ];
  };

  services.ollama = {
    enable = true;
  };
}
