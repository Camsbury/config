{ config, pkgs, ... }:

let
  pruneLorriRoots = ../../scripts/prune-lorri-roots.bb;
  codeMaatDer = import ../derivations/code-maat/default.nix;
  code-maat =
    with builtins;
    with pkgs;
    callPackage codeMaatDer {
      inherit stdenvNoCC;
      inherit fetchurl;
    };
in
{
  imports = [
    # ./bb-nrepl.nix
    ./docker.nix
    ./postgres.nix
  ];
  environment = {
    systemPackages = with pkgs; [
      babashka
      binutils
      code-maat
      difftastic
      direnv
      cmacs-emacs
      entr
      gdb
      gh
      git
      git-extras
      hub
      glibc
      go-grip
      gnumake
      google-cloud-sdk
      kubectl
      loccount
      nixd
      nixfmt
      update-nix-fetchgit
      pkgs.prettier
      pandoc
      patchelf # patch dynamic libs/bins
      python3
      shellcheck
      sqlite
      tmux
    ];

    variables = {
      DEV_HOME = "/home/${toString config.users.users.default.name}/projects";
    };
  };
  services.lorri.enable = true;

  # lorri keeps a GC root for every shell it ever built, and nh clean never
  # ages them out. This prunes each project down to its active shell; the
  # old shells' store paths then go at the next nh-clean run. User units
  # cannot be ordered against that system timer, so this runs daily at
  # 23:00: every GC then sees pruned roots, whatever day nh-clean runs,
  # and never in the same second. Pruning more often costs nothing: an
  # unrooted shell stays in the store until the GC, and lorri relinks it
  # on its next build.
  systemd.user.services.lorri-prune = {
    description = "Prune lorri GC roots to each project's active shell";
    unitConfig.ConditionPathIsDirectory = "%h/.cache/lorri/gc_roots";
    # What nixpkgs' lorri daemon unit puts on PATH for lorri itself.
    path = [
      config.services.lorri.package
      config.nix.package
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.babashka}/bin/bb ${pruneLorriRoots}";
    };
    startAt = "*-*-* 23:00:00";
  };
  # Catch up on a run missed while logged out.
  systemd.user.timers.lorri-prune.timerConfig.Persistent = true;
}
