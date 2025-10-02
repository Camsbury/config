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
      bottom
      curl
      dua
      du-dust
      eza
      fzf
      htop
      httpie
      jq
      killall
      man-pages
      nix-index
      oh-my-zsh
      pciutils
      sourceHighlight
      tldr
      tree
      unzip
      usbutils
      vim
      wget
      xclip # copy paste stuff
      zip
      zsh
    ];
  };

  services.udisks2.enable = true;

  console = {
    # font = "Go Mono";
    useXkbConfig = true;
  };

  documentation.dev.enable = true;

  programs.bash.completion.enable = true;

  users.users.default.shell = pkgs.zsh;
}
