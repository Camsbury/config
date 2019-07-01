numUUIDs ? 1:
let
  pkgs = import <nixpkgs> {};
  uuidGenN = ''
    from uuid import uuid4
    for i in range(${numUUIDs}):
        print(str(uuid4()))
  '';
in
  with pkgs;
  mkDerivation {
    name = "uuidGenN";
    buildInputs = [
      python36
    ];
    UUID_GEN_N = "python -c ${uuidGenN}";
  }
