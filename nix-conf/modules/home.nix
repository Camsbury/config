{ pkgs, config, ... }:
let
  sym = config.lib.file.mkOutOfStoreSymlink;
in
{
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  home.file = {
    ".Xresources".source = ../../Xresources;
    ".clojure".source = sym ../../clojure;
    ".config/dunst/dunstrc".source = sym ../../dunstrc;
    ".gitconfig".source = sym ../../gitconfig;
    ".gitignore".source = sym ../../global-gitignore;
    ".gnupg/gpg-agent.conf".source = ../../gpg-agent.conf;
    ".gnupg/gpg.conf".source = ../../gpg.conf;
    ".helpers.zsh.inc".source = ../../helpers.zsh.inc;
    ".offlineimap.py".source = ../../offlineimap.py;
    ".offlineimaprc".source = ../../offlineimaprc;
    ".scripts".source = ../../scripts;
    ".shells".source = ../shells;
    ".zshrc".source = ../../zshrc;
  };
}
