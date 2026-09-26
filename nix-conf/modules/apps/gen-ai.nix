{ config, pkgs, ... }:

# Opt-in: machines import this file directly, and ./default.nix does not.
# Local AI: the llama.cpp runner, the LM Studio front end, and peon-ping.
#
# CUDA comes from hardware/nvidia.nix, which sets `cudaSupport` for the
# whole machine, so llama-cpp here builds for CPU on a machine without an
# NVIDIA card. Nothing asks for CUDA in this file.
{
  environment = {
    systemPackages = with pkgs; [
      llama-cpp
      lmstudio
      peon-ping
    ];
  };
}
