#!/bin/bash

mv /etc/nixos/configuration.nix /etc/nixos/configuration-backup.nix;
rm ~/.emacs.d;
rm ~/.gitconfig;
rm ~/.gnupg/.gpg-agent.conf;
rm ~/.scripts;
rm ~/.shells;
rm ~/.tmux.conf;
rm ~/.xmonad;
rm ~/.Xresources;
rm ~/.zshrc;
ln -s ~/projects/Camsbury/config/configuration.nix /etc/nixos/configuration.nix;
ln -s ~/projects/Camsbury/config/emacs.d ~/.emacs.d;
ln -s ~/projects/Camsbury/config/gitconfig ~/.gitconfig;
ln -s ~/projects/Camsbury/config/gpg-agent.conf ~/.gnupg/.gpg-agent.conf;
ln -s ~/projects/Camsbury/config/scripts ~/.scripts;
ln -s ~/projects/Camsbury/config/shells ~/.shells;
ln -s ~/projects/Camsbury/config/tmux.conf ~/.tmux.conf;
ln -s ~/projects/Camsbury/config/xmonad ~/.xmonad;
ln -s ~/projects/Camsbury/config/Xresources ~/.Xresources;
ln -s ~/projects/Camsbury/config/zshrc ~/.zshrc;
