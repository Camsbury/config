# The NVIDIA vendor stack: what any NVIDIA card needs, no matter which card.
# A card module imports this file, so a machine gets the stack by importing
# its card.
{ pkgs, ... }:

let
  # The CUDA policy (decision 0023). Every package that can use CUDA is
  # built with it, so a package added later gets GPU support without
  # anyone asking for it. A package that the flag turns into a long
  # uncached source build joins this list instead and comes from a
  # CUDA-free instance of the same nixpkgs, which keeps its derivation
  # identical to the cached one. Measured 2026-09-25: the flag alone cost
  # 78 source builds and 5.9 GiB; with these five excluded, poseidon's
  # system derivation is unchanged.
  cpuOnly = [
    "firefox-unwrapped" # links onnxruntime
    "calibre" # pulls torch through piper-tts
    "thunderbird" # links onnxruntime
    "krita" # pulls opencv and suitesparse
    "gimp" # pulls opencv and suitesparse
  ];

  # The CUDA-free instance takes no overlays, so an overlay in
  # overlays/core.nix does not reach a package on the list. Checked
  # 2026-09-26: that overlay defines none of the five.
  cpuOnlyOverlay =
    final: prev:
    let
      noCuda = import prev.path {
        inherit (prev.stdenv.hostPlatform) system;
        config = prev.config // {
          cudaSupport = false;
        };
      };
    in
    prev.lib.genAttrs cpuOnly (name: noCuda.${name});
in
{
  hardware.graphics.enable = true;

  nixpkgs.config.cudaSupport = true;
  nixpkgs.overlays = [ cpuOnlyOverlay ];

  environment.systemPackages = [
    # The toolkit comes from the main pin on purpose: the toolkit and every
    # CUDA build then share one CUDA version (12.9 today). A newer CUDA is a
    # bump of the whole pin, not of the toolkit alone.
    pkgs.cudatoolkit
    # nvtop is a vendor tool: it reads NVIDIA GPU counters, so it belongs
    # with the card, not with the programs that happen to use the GPU.
    pkgs.nvtopPackages.full
  ];
}
