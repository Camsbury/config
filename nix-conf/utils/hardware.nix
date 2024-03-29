let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixos-hardware";
    # rev    = "f7540d6c27704ec0fe56ecc8b2a9b663181850b0";
    # sha256 = "1rr470h5frly4a6wwpm1pmfgv57v5f7zwlc73sdx93ms7pc050lf";
    # rev = "16fca9df230408608846940981b4037762420b1b";
    # sha256 = "0nvak6dmlcgc4m5s6di82c06c95cmc4iys1ky14y5di27r7qnrma";
    # NOTE: flip
    # rev = "c3c66f6db4ac74a59eb83d83e40c10046ebc0b8c";
    # sha256 = "1h5x8zgmxzdj15pgssn7nihi24ni63571q75hdpsz7zxgyjw2nyh";
    # rev = "feceb4d24f582817d8f6e737cd40af9e162dee05";
    # hash = "sha256-h8e3+5EZFbYHTMb0DN2ACuQTJBNHpqigvmEV1w2WIuE=";

    # rev = "429f232fe1dc398c5afea19a51aad6931ee0fb89";
    # hash = "sha256-aqKCUD126dRlVSKV6vWuDCitfjFrZlkwNuvj5LtjRRU=";

    rev = "72d53d51704295f1645d20384cd13aecc182f624";
    hash = "sha256-5VSB63UE/O191cuZiGHbCJ9ipc7cGKB8cHp0cfusuyo=";
  }
