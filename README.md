# My Config Files

## NixOS Setup
- install NixOS
- create a user with a home directory
- clone the repo somewhere in that directory
- copy the example.nix files without the example part, and edit to match the system (be sure the user info is good)
- symlink configuration.nix into /etc/nixos/configuration.nix
- symlink zshrc into ~/.zshrc
- symlink cmacs into ~/.emacs.d
- run `sudo nixos-rebuild switch && reboot`
