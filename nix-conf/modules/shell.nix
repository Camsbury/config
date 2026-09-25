{ config, pkgs, ... }:

# The interactive command line: the login shell, its configuration
# (zsh.nix), and the command-line tools used from it.
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
      aria2
      autojump
      bat
      bottom
      curl
      dua
      dust
      eza
      fzf
      htop
      httpie
      jq
      killall
      oh-my-zsh
      ouch # for easy compression semantics
      pciutils
      sourceHighlight
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

  programs.bash.completion.enable = true;

  users.users.default.shell = pkgs.zsh;
}
