# dev: tools you use on a project: version control, build, debug, lint and
# format, language runtimes, cloud and cluster CLIs; services you develop
# against (databases, containers, VMs, device SDKs)
#
# The always-on development subjects every machine gets, as sections. The
# opt-in ones (./android.nix, ./influxdb.nix, ./virtualization.nix) are
# imported by machines directly, and this file does not import them. A
# setting belongs here only when its subject is on the list above.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    # --- docker ---
    {
      environment.systemPackages = with pkgs; [
        docker
        docker-compose
      ];

      users = {
        groups.docker = { };
        users.default.extraGroups = [ "docker" ];
      };

      virtualisation.docker = {
        enable = true;
        enableOnBoot = true;
      };
    }

    # --- lorri and its GC-root prune ---
    (
      let
        pruneLorriRoots = ../../../scripts/prune-lorri-roots.bb;
      in
      {
        services.lorri.enable = true;

        # lorri keeps a GC root for every shell it ever built, and nh clean
        # never ages them out. This prunes each project down to its active
        # shell; the old shells' store paths then go at the next nh-clean
        # run. User units cannot be ordered against that system timer, so
        # this runs daily at 23:00: every GC then sees pruned roots,
        # whatever day nh-clean runs, and never in the same second. Pruning
        # more often costs nothing: an unrooted shell stays in the store
        # until the GC, and lorri relinks it on its next build.
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
    )

    # --- postgres ---
    {
      services.postgresql = {
        enable = true;
        enableTCPIP = true;
        # port = 5432;
        package = pkgs.postgresql;
        authentication = pkgs.lib.mkOverride 10 ''
          local all all              trust
          host  all all 127.0.0.1/32 trust
          host  all all ::1/128      trust
        '';
        # #type database  DBuser  auth-method optional_ident_map
        # local sameuser  all     peer        map=superuser_map

        identMap = ''
          # ArbitraryMapName systemUser DBUser
             superuser_map      root      postgres
             superuser_map      postgres  postgres
             # Let other names login as themselves
             superuser_map      /^(.*)$   \1
        '';
      };
    }

    # --- toolchain ---
    (
      let
        codeMaatDer = import ../../derivations/code-maat/default.nix;
        code-maat =
          with builtins;
          with pkgs;
          callPackage codeMaatDer {
            inherit stdenvNoCC;
            inherit fetchurl;
          };
      in
      {
        environment = {
          systemPackages = with pkgs; [
            babashka
            binutils
            code-maat
            difftastic
            direnv
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
            patchelf # patch dynamic libs/bins
            python3
            shellcheck
            sqlite
          ];

          variables = {
            DEV_HOME = "/home/${toString config.users.users.default.name}/projects";
          };
        };
      }
    )
  ];
}
