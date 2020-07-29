{ pkgs, ... }:
let
  unstable = import ../utils/unstable.nix {};
in
{
  nixpkgs.config.allowUnfree = true;
  programs.home-manager.enable = true;

  home.file = {
    ".Xresources".source = ../../Xresources;
    ".gitconfig".source = ../../gitconfig;
    ".gnupg/gpg-agent.conf".source = ../../gpg-agent.conf;
    ".gnupg/gpg.conf".source = ../../gpg.conf;
    ".helpers.zsh.inc".source = ../../helpers.zsh.inc;
    ".offlineimap.py".source = ../../offlineimap.py;
    ".offlineimaprc".source = ../../offlineimaprc;
    ".scripts".source = toString ../../scripts;
    ".shells".source = toString ../shells;
    ".zshrc".source = ../../zshrc;
  };
}
