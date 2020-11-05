let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    # nixos-unstable
    # rev = "ae6bdcc53584aaf20211ce1814bea97ece08a248";
    # sha256 = "0hjhznns1cxgl3hww2d5si6vhy36pnm53hms9h338v6r633dcy77";
    # rev = "05f0934825c2a0750d4888c4735f9420c906b388";
    # sha256 = "1g8c2w0661qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
    # rev = "22a3bf9fb9edad917fb6cd1066d58b5e426ee975";
    # sha256 = "1g8c2w0664qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
    # rev = "22c98819ccdf042b30103d827d35644ed0f17831";
    # sha256 = "067sz4zskc7ad1cjxhszgdqzm51969jyqlkz2rss0y5a7y3pli91";
    # rev = "16fc531784ac226fb268cc59ad573d2746c109c1";
    # sha256 = "0qw1jpdfih9y0dycslapzfp8bl4z7vfg9c7qz176wghwybm4sx0a";
    # rev = "1179840f9a88b8a548f4b11d1a03aa25a790c379";
    # sha256 = "00jy37wj04bvh299xgal2iik2my9l0nq6cw50r1b2kdfrji8d563";
    # rev = "5aba0fe9766a7201a336249fd6cb76e0d7ba2faf";
    # sha256 = "05gawlhizp85agdpw3kpjn41vggdiywbabsbmk76r2dr513188jz";
    rev = "0da76dab4c2acce5ebf404c400d38ad95c52b152";
    sha256 = "1lj3h4hg3cnxl3avbg9089wd8c82i6sxhdyxfy99l950i78j0gfg";
  })
