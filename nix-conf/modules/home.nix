{ pkgs, config, ... }:
let
  sym = config.lib.file.mkOutOfStoreSymlink;
in
  {
    nixpkgs.config.allowUnfree = true;
    programs.home-manager.enable = true;

    xsession.numlock.enable = true;

    home.stateVersion = "22.05";

    dconf = {
      enable = true;
      settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";
    };
    gtk = {
      enable = true;
      theme = {
        name = "Tokyo-Night";
        package = pkgs.tokyonight-gtk-theme;
      };

      gtk3.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };

      gtk4.extraConfig = {
        Settings = ''
          gtk-application-prefer-dark-theme=1
        '';
      };
    };


    home.file = {
      ".Xresources".source = ../../Xresources;
      ".clojure".source = sym ../../clojure;
      ".config/dunst/dunstrc".source = sym ../../dunstrc;
      ".config/gollama/config.json".source = sym ../../gollama-conf.json;
      ".gitconfig".source = sym ../../gitconfig;
      ".gitignore".source = sym ../../global-gitignore;
      ".gnupg/gpg-agent.conf".source = ../../gpg-agent.conf;
      ".gnupg/gpg.conf".source = ../../gpg.conf;
      ".helpers.zsh.inc".source = ../../helpers.zsh.inc;
      ".offlineimap.py".source = ../../offlineimap.py;
      ".offlineimaprc".source = ../../offlineimaprc;
      ".rgignore".source = sym ../../rgignore;
      ".scripts".source = sym ../../scripts;
      ".shells".source = ../shells;
      ".tmux.conf".source = ../../tmux.conf;
      ".zshrc".source = ../../zshrc;
    };
  }
