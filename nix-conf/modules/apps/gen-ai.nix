{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Local AI: the llama.cpp runner, the LM Studio front end, and peon-ping.
#
# CUDA comes from hardware/nvidia.nix, which sets `cudaSupport` for the
# whole machine, so llama-cpp here builds for CPU on a machine without an
# NVIDIA card. Nothing asks for CUDA in this file.
{
  environment = {
    vairables = {
      ECA_LIGHT_MODEL="claude-sonnet-5-5";
      ECA_DEFAULT_MODEL="claude-opus-5-5";
      ECA_HEAVY_MODEL="claude-fable-5-1";
    };
    systemPackages = with pkgs; [
      llama-cpp
      lmstudio
      peon-ping
    ];
  };
}
