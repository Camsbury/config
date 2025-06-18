{ config, pkgs, ... }:

{
  environment = {
    variables = {
      OLLAMA_MODELS = "/media/monoid/ollama-models";
    };
    systemPackages = with pkgs; [
      aider-chat
      gollama
      lmstudio
    ];
  };

  services.ollama = {
    enable = true;
  };
}
