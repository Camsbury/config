{ config, pkgs, ... }:

{
  environment = {
    systemPackages = with pkgs; [
      (llama-cpp.override { cudaSupport = true; })
      lmstudio
      peon-ping
    ];
  };
}
