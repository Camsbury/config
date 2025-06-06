{
  lib,
  stdenv,
  callPackage,
  ...
}:
let
  pname = "lmstudio";
  version = "0.3.14";
  rev = "5";
  meta = {
    description = "LM Studio is an easy to use desktop app for experimenting with local and open-source Large Language Models (LLMs)";
    homepage = "https://lmstudio.ai/";
    license = lib.licenses.unfree;
    mainProgram = "lmstudio";
    maintainers = with lib.maintainers; [
      cig0
      eeedean
      crertel
    ];
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
in
  callPackage ./linux.nix {
    inherit
      pname
      version
      rev
      meta
      ;
  }
