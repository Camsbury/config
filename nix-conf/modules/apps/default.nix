# apps: programs you launch for a task, grouped by task (browsing,
# communication, documents, media, study, sync, torrents, art, music,
# games, email, local AI), and a daemon that serves one of them
#
# The always-on apps every machine gets, as sections. The task-specific
# ones (./art.nix, ./email.nix, ./gaming.nix, ./gen-ai.nix, ./music.nix)
# are opt-in, so machines import them directly and this file does not. A
# setting belongs here only when its subject is on the list above.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    # --- browsers ---
    # Web browsers and the default one.
    {
      environment = {
        variables = {
          BROWSER = "firefox";
        };
        systemPackages = with pkgs; [
          chromium
          firefox
          google-chrome # for certain features
        ];
      };
    }

    # --- communication ---
    # Chat and mail clients.
    {
      environment.systemPackages = with pkgs; [
        discord
        # element-desktop
        signal-desktop
        slack
        telegram-desktop
        thunderbird
      ];
    }

    # --- documents ---
    # Reading and writing documents: viewers, typesetting, conversion, and
    # the tools that writing uses (plotting, spell checking).
    {
      environment.systemPackages = with pkgs; [
        calibre # ebook stuff
        ghostscript # for viewing pdfs
        gnuplot
        ispell # used for spell check
        pandoc
        texliveFull # latex!
        zathura
      ];
    }

    # --- dropbox ---
    # Maestral, the Dropbox sync daemon, as a user service.
    {
      environment = {
        systemPackages = with pkgs; [
          maestral
        ];
      };

      systemd.user.services.maestral = {
        description = "Maestral daemon";

        wantedBy = [ "default.target" ];

        serviceConfig = {
          Type = "notify";
          NotifyAccess = "exec";
          ExecStart = "${pkgs.maestral}/bin/maestral start -f";
          ExecStop = "${pkgs.maestral}/bin/maestral stop";
          ExecStopPost = ''
            ${pkgs.bash}/bin/bash -c "if [ $SERVICE_RESULT != success ]; then \
            ${pkgs.libnotify}/bin/notify-send Maestral 'Daemon failed'; fi"
          '';
          WatchdogSec = "30s";
        };
      };
    }

    # --- media ---
    # Playing, recording, and editing audio, video, and images.
    {
      environment.systemPackages = with pkgs; [
        audacity
        gimp
        mpg123 # used in emacs and other quick mp3 playing
        spotify # non-free
        vlc
      ];
    }

    # --- study ---
    # Study tools: spaced-repetition flashcards and chess study.
    {
      environment.systemPackages = with pkgs; [
        anki
        pgn-extract # chess utils
        # scid-vs-pc # chess
      ];
    }

    # --- transmission ---
    # The transmission BitTorrent daemon. A machine may set its own
    # services.transmission.settings.download-dir.
    {
      services.transmission = {
        enable = true;
        openFirewall = true;
        package = pkgs.transmission_4;
      };

      systemd.tmpfiles.rules = [
        "d ${toString config.services.transmission.settings.download-dir} 0770 transmission transmission - -"
      ];
    }
  ];
}
