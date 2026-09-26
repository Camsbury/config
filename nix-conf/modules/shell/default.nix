# shell: the prompt (zsh, including every tool's shell hook and the default
# account's login shell); general command-line tools that are useful in any
# directory; manuals and option docs
#
# The interactive command line. The prompt is large enough to live in its
# own file (./zsh.nix); the rest are sections here. A setting belongs here
# only when its subject is on the list above.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./zsh.nix
  ];

  config = lib.mkMerge [
    # --- command-line tools and EDITOR ---
    # Tools that are useful in any directory, and the editor every program
    # falls back to.
    {
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
          entr
          eza
          fzf
          htop
          httpie
          inotify-tools
          jq
          killall
          oh-my-zsh
          ouch # for easy compression semantics
          pciutils
          sourceHighlight
          tmux
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
    }

    # --- manuals and option docs ---
    {
      documentation.dev.enable = true;

      environment.systemPackages = with pkgs; [
        man-pages
        tldr
      ];

      # Publish the NixOS option docs at a stable path, so tools can read
      # option names, types, and descriptions without evaluating the system.
      # The configuration.nix(5) man page is built from the same file, so
      # this adds no build. The manual exists only while NixOS docs are
      # enabled.
      environment.etc."nixos/options.json" = lib.mkIf config.documentation.nixos.enable {
        source = "${config.system.build.manual.optionsJSON}/share/doc/nixos/options.json";
      };
    }

    # --- search ---
    # Finding files and finding text in them.
    {
      environment.systemPackages = with pkgs; [
        ack
        fd
        lsof
        ripgrep
        silver-searcher
      ];
    }
  ];
}
