let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    # my fork
    # owner = "Camsbury";
    repo  = "nixpkgs";
    # rev = "e1f8852faac";
    # sha256 = "16zxn0lnj10wcdarsyazc2137lqgxb0fi80yny91mzbzisb2w7gs";
    # Camsbury
    # rev = "90b3800db9f633aaf25e09902a5866f7355f2548";
    # sha256 = "1vrhwlwc7x3f0xn6cgckrfp8vky0yws30d52hq3miy122d03gcc0";
    # rev = "0dde1033180";
    # sha256 = "1p8d5dfia1sfrc43iyr4b9l43hgmf36f5piz4lgrm9drvl16s333";
    # rev = "8d8a28b47b7";
    # sha256 = "1s29nc3ppsjdq8kgbh8pc26xislkv01yph58xv2vjklkvsmz5pzm";
    # rev = "31ffc50c571";
    # rev = "ac169ec6371f0d835542db654a65e0f2feb07838";
    # sha256 = "0bwjyz15sr5f7z0niwls9127hikp2b6fggisysk0cnk3l6fa8abh";
    # rev = "7f9b6e2babf"; # pin
    # sha256 = "03nb8sbzgc3c0qdr1jbsn852zi3qp74z4qcy7vrabvvly8rbixp2";
    rev = "710fed5a248";
    hash = "sha256-kCmnDeiaMsdhfnNKjxdOzwRh2H6eQb8yWAL+nNabC/Y=";
})
