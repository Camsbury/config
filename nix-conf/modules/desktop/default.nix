# desktop: the X session, EXWM and cmacs; display manager and greeter;
# compositor; theme and wallpaper; screen lock; fonts; notifications,
# including spoken alerts; screen color temperature; keyboard layout (xkb,
# which the console also follows); media keys; sound
#
# The graphical session and everything that draws in it. Subjects big
# enough for their own file are imported below; ./compose-key.nix is
# opt-in, so machines import it directly. A setting belongs here only when
# its subject is on the list above.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./theme.nix
    ./screen-lock.nix
    ./media-keys.nix
    ./login-greeter.nix
  ];

  config = lib.mkMerge [
    # --- cmacs and EXWM ---
    # cmacs is the Emacs build, and EXWM makes it the window manager, so
    # the only session the display manager offers is "none+exwm".
    {
      environment = {
        systemPackages = with pkgs; [
          cmacs
          cmacs-emacs
          cmacs-load-path
        ];

        variables = {
          EMACSLOADPATH = "${pkgs.cmacs-emacs.deps}/share/emacs/site-lisp";
        };
      };

      services.displayManager.defaultSession = "none+exwm";
      services.xserver = {
        displayManager = {
          sessionCommands = "${pkgs.xhost}/bin/xhost +SI:localuser:$USER";
        };
        windowManager = {
          session = lib.singleton {
            name = "exwm";
            start = "${pkgs.cmacs}/bin/cmacs";
          };
        };
      };

      # An eca bump that breaks the ECA upstream adapter fails the rebuild.
      system.checks = [ pkgs.cmacs-eca-upstream-guard ];
    }

    # --- color temperature ---
    {
      environment.systemPackages = [ pkgs.redshift ];
    }

    # --- compositor ---
    {
      services.picom = {
        enable = true;
        backend = "glx";
        vSync = true;
        shadow = false;
        fade = false;
        settings = {
          unredir-if-possible = true; # fullscreen games bypass
        };
      };
    }

    # EXWM's Emacs frame is opaque and covers the whole screen, so picom
    # treats it as a fullscreen window and unredirects. Every dunst
    # notification then forces a re-redirect -> visible black flash on
    # NVIDIA. Excluding the Emacs frame stops that, while real fullscreen
    # games (their own X windows, not class Emacs) still trigger the
    # bypass. The black flash is an NVIDIA fault, so this guard is why
    # machines without an NVIDIA card do not get the exclude.
    (lib.mkIf config.hardware.nvidia.enabled {
      services.picom.settings.unredir-if-possible-exclude = [
        "class_g = 'Emacs'"
      ];
    })

    # --- fonts ---
    {
      fonts = {
        fontDir.enable = true;
        enableGhostscriptFonts = true;
        packages = with pkgs; [
          corefonts
          dejavu_fonts
          go-font
          google-fonts
          noto-fonts
          powerline-fonts
          roboto-mono
          ubuntu-classic
        ];
      };
    }

    # --- keyboard ---
    # The layout and key repeat, in X and on the console, plus the tools
    # that switch and remap it. Machines add layout variants on top
    # (./compose-key.nix, ../hardware/builtin-keyboard.nix).
    {
      services.xserver = {
        autoRepeatDelay = 300;
        autoRepeatInterval = 15;
        xkb.layout = "us";
      };

      # The console follows the X layout.
      console.useXkbConfig = true;

      environment.systemPackages = with pkgs; [
        xkb-switch
        xmodmap
      ];
    }

    # --- notifications ---
    {
      environment.systemPackages = with pkgs; [
        dunst
        espeak # tts
        libnotify
        speechd # tts
      ];
    }

    # --- sound ---
    # Under the 50-line rule, so it stays a section here instead of
    # becoming ./sound.nix.
    {
      environment.systemPackages = with pkgs; [
        pavucontrol
        alsa-utils
        qpwgraph
      ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        extraConfig.pipewire = {
          "99-disable-bell" = {
            "context.properties" = {
              "module.x11.bell" = false;
            };
          };
        };
        pulse.enable = true;
        jack.enable = true;

        wireplumber.enable = true;
      };
    }

    # The bluez5 codec settings and the headset-profile autoswitch only do
    # something when a Bluetooth radio is present, so
    # `hardware.bluetooth.enable` is the switch: a machine that imports no
    # Bluetooth module does not get them. The guard wraps a whole attribute
    # set here, because `wireplumber.extraConfig` is `attrsOf (attrsOf
    # json)` and an `mkIf` inside the JSON value is a type error.
    (lib.mkIf config.hardware.bluetooth.enable {
      services.pipewire.wireplumber.extraConfig = {
        "wireplumber.settings" = {
          "bluetooth.autoswitch-to-headset-profile" = false;
        };
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.roles" = [
            "a2dp_sink"
            "a2dp_source"
          ];
        };
      };
    })

    # --- X session ---
    {
      services.xserver = {
        enable = true;
        displayManager.lightdm.enable = true;
      };

      # Lets cmacs's ck/restart-display-manager recover a broken session.
      security.sudo.extraRules = [
        {
          users = [ "ALL" ];
          commands = [
            {
              command = "/usr/bin/env systemctl restart display-manager.service";
              options = [ "NOPASSWD" ];
            }
          ];
        }
      ];
    }
  ];
}
