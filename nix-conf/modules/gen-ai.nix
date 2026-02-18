{ config, pkgs, ... }:

{
  environment = {
    variables = {
      OLLAMA_MODELS = "/media/camsbury/ollama-models";
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
