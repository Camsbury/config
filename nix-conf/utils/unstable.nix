let
  inherit (import <nixpkgs> {}) fetchFromGitHub;
in
  import (fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs-channels";
    # nixos-unstable
    # rev = "ae6bdcc53584aaf20211ce1814bea97ece08a248";
    # sha256 = "0hjhznns1cxgl3hww2d5si6vhy36pnm53hms9h338v6r633dcy77";
    # rev = "05f0934825c2a0750d4888c4735f9420c906b388";
    # sha256 = "1g8c2w0661qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
    # rev = "22a3bf9fb9edad917fb6cd1066d58b5e426ee975";
    # sha256 = "1g8c2w0664qn89ajp44znmwfmghbbiygvdzq0rzlvlpdiz28v6gy";
    # rev = "22c98819ccdf042b30103d827d35644ed0f17831";
    # sha256 = "067sz4zskc7ad1cjxhszgdqzm51969jyqlkz2rss0y5a7y3pli91";
    rev = "16fc531784ac226fb268cc59ad573d2746c109c1";
    sha256 = "0qw1jpdfih9y0dycslapzfp8bl4z7vfg9c7qz176wghwybm4sx0a";
  })
