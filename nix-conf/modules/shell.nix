{ config, pkgs, ... }:

{
  imports = [
    ./zsh.nix
  ];

  environment = {
    variables = {
      EDITOR = "vim";
      HISTCONTROL = "ignorespace";
    };
    systemPackages = with pkgs; [
      autojump
      bat
      curl
      exa
      fzf
      htop
      httpie
      jq
      killall
      man-pages
      nix-index
      oh-my-zsh
      sourceHighlight
      tldr
      tree
      udisks # manage drives
      unzip
      usbutils
      vim
      wget
      xclip # copy paste stuff
      zip
      zsh
    ];
  };

  console = {
    # font = "Go Mono";
    useXkbConfig = true;
  };

  documentation.dev.enable = true;

  programs.bash.enableCompletion = true;

  users.users.default.shell = pkgs.zsh;
}
