{ config, lib, pkgs, ... }:

let
  cfg = config.mg.restic;

  # Home directory of the backup user, taken from the actual user
  # declaration (falls back to /home/<user> if the user is not declared).
  homeDir = config.users.users.${cfg.user}.home or "/home/${cfg.user}";

  # Backup sources/excludes shared by every machine. Add per-machine extras
  # via the mg.restic additionalSources/additionalExcludes options.
  defaultSources = [
    "/"
    "/home"
  ];

  defaultExcludes = [
    # nix store should be its own btrfs subvolume so not included
    # unless explicitly added to sources
    "/nix"
    ".cache"
    "node_modules"
    "/swap/swapfile"

    # linux kernel
    "${homeDir}/dev/linux"

    ".mozilla/firefox/**/morgue"
    "/home/*/.config/Slack/Cache"
    "/var/lib/docker"
    "VirtualBox VMs/**/Snapshots"
    # tob prebuilt libs
    "cxx-common"
    # android sdk stuff
    "${homeDir}/Android"
    # steam games
    "${homeDir}/.local/share/Steam/steamapps/common"
    # go deps/binaries
    "${homeDir}/go"
  ];

  allSources = defaultSources ++ cfg.additionalSources;
  allExcludes = defaultExcludes ++ cfg.additionalExcludes;

  # Absolute binary paths. The restic systemd unit sets `path = [ ssh ]`,
  # which replaces PATH, so nothing else is resolvable by name inside
  # preStart / postStop / the notify services. Reference everything by path.
  resticBin = "${pkgs.restic}/bin/restic";

  # Shared backup flags (resticprofile: exclude-caches, one-file-system,
  # tag, schedule-lock-wait 2h). `--no-error-on-warning` is not a restic flag
  # (resticprofile handled it); `--lock-wait` is likewise absent — the restic
  # equivalent for waiting on a held lock is `--retry-lock`.
  commonBackupArgs = [
    "--exclude-caches"
    "--one-file-system"
    "--tag" cfg.name
    "--tag" "full"
    "--retry-lock" "2h"
  ];

  # Retention policy, faithful to the original (resticprofile retention).
  pruneOptsList = [
    "--keep-hourly" "1"
    "--keep-daily" "3"
    "--keep-weekly" "2"
    "--keep-monthly" "6"
    "--keep-tag" "forever"
    "--host" cfg.name
    "--tag" cfg.name
    "--tag" "full"
    "--retry-lock" "2h"
  ];

  dailyTimer = {
    OnCalendar = "08:00:00";
    Persistent = true;
  };

  monthlyTimer = {
    OnCalendar = "*-*-01 12:00:00";
    Persistent = true;
  };

  # Prepare/cleanup commands per backend. `restic unlock` self-heals stale
  # locks from dropped connections before every run (resticprofile only did
  # this monthly via prune). The module also auto-runs `restic unlock` before
  # the prune command, so the prune prepare only needs wakeup/mount.
  resticUnlockCmd = "${resticBin} unlock";

  sshPrepare = lib.concatStringsSep "\n" (
    lib.optional cfg.sshWakeEnabled "${sshWakeup}/bin/restic-ssh-wakeup"
    ++ [ resticUnlockCmd ]
  );

  # The local backup disk is mounted/unmounted by a systemd `.mount` unit
  # (see systemd.mounts below) on demand: the backup/prune services
  # `Requires`/`After` it, so it mounts when a backup starts and unmounts
  # when it stops. The prepare step therefore only needs `restic unlock`
  # (the repo is reachable once systemd has mounted the disk).
  localPrepare = resticUnlockCmd;

  # systemd `.mount` unit name for the local backup disk. Let `systemd-escape`
  # compute the canonical name (paths are encoded: `/` -> `-`, `-` -> `\x2d`)
  # rather than hand-escaping it.
  mountUnit = let
    escaped = builtins.readFile (pkgs.runCommand "restic-local-mount-unit"
      { nativeBuildInputs = [ pkgs.systemd ]; }
      ''
        systemd-escape --path /mnt/backup-local-${cfg.name} | tr -d '\n' > $out
      '');
  in escaped + ".mount";

  # SSH wakeup helper (resticprofile's ssh_wakeup.sh), deployed as a package.
  sshWakeup = pkgs.writeShellScriptBin "restic-ssh-wakeup" ''
    # Wakes the SSH backup target before a backup.
    echo "Waking up target"

    i=1
    while [ "$i" -le 5 ]; do
      ssh router ether-wake -i br0 BC:5F:F4:36:B6:A1
      if ssh -o BatchMode=yes -o ConnectTimeout=5 homeserver true; then
        echo "Server woken up successfully"
        exit 0
      fi
      sleep 5
      i=$((i + 1))
    done

    echo "Wakeup failed"
    exit 1
  '';

  # Desktop/Gotify failure notifications are provided by the generic
  # notification module (mg.notify, see ./notify.nix). This module only
  # declares which units to watch via mg.notify.onFailure (see config below).

  # Managed dispatcher on top of the built-in `restic-<backend>` wrappers.
  # Mounts / wakes the target so the repo is reachable, then delegates to the
  # original wrapper (which sets the env and execs restic). It deliberately
  # does NOT run `restic unlock` — that only belongs in the automatic backup's
  # prepare step, so diagnoses here don't disturb locks.
  resticp = pkgs.writeShellScriptBin "resticp" ''
    # Usage: resticp <backend> <restic args...>
    #   sudo resticp local snapshots      # mounts, runs, unmounts
    #   sudo resticp rest check
    if [ "$#" -lt 1 ]; then
      echo "Usage: $0 <backend> <restic args...>" >&2
      exit 1
    fi
    backend="$1"
    shift

    prepare() {
      case "$backend" in
        local)
          # Mount via the systemd .mount unit (on demand).
          systemctl start ${mountUnit} \
            || { echo "resticp: failed to mount backup disk (${mountUnit})" >&2; exit 1; }
          ;;
        ssh)
          ${lib.optionalString cfg.sshWakeEnabled "restic-ssh-wakeup || true"}
          ;;
      esac
    }
    cleanup() {
      case "$backend" in
        local)
          systemctl stop ${mountUnit}
          ;;
      esac
    }

    prepare
    trap cleanup EXIT
    "restic-$backend" "$@"
  '';

  # Nice (low IO priority) wiring for one backend's backup and prune units.
  # For the local backend the backup disk is mounted on demand via the
  # systemd `.mount` unit. Failure notifications are attached separately via
  # mg.notify.onFailure (see config below), so this override stays a plain
  # service attrset.
  mkServiceOverrides = b:
    let
      mountReq = lib.optionalAttrs (b == "local") {
        requires = [ mountUnit ];
        after = [ mountUnit ];
      };
    in
    {
      "restic-backups-${b}" = {
        serviceConfig.Nice = 19;
      } // mountReq;
      "restic-backups-${b}-prune" = {
        serviceConfig.Nice = 19;
      } // mountReq;
    };

  enabledBackends = lib.optional cfg.enableRest "rest"
    ++ lib.optional cfg.enableSsh "ssh"
    ++ lib.optional cfg.enableLocal "local";

  # Failure notifications for each enabled backend's backup and prune units,
  # delegated to the generic notification module (mg.notify). The module
  # generates the oneshot notifier services and wires each unit's OnFailure.
  #
  # Channel selection per backend: a `perBackend` override wins, otherwise the
  # module-wide `cfg.notify.channels`. When neither is set (null) the `channels`
  # key is omitted so the entry inherits mg.notify.defaultChannels.
  resticChannelsFor = b:
    if cfg.notify.perBackend ? ${b} then cfg.notify.perBackend.${b} else cfg.notify.channels;

  mkResticEntry = b: base:
    let chans = resticChannelsFor b;
    in base // lib.optionalAttrs (chans != null) { channels = chans; };

  resticNotifyOnFailure = lib.mkMerge (map (b: {
    "restic-backups-${b}" = mkResticEntry b {
      title = "restic backup failed: ${cfg.name}/${b}";
      message = "Job restic-backups-${b} failed.";
      appName = "restic";
      urgency = "critical";
    };
    "restic-backups-${b}-prune" = mkResticEntry b {
      title = "restic prune failed: ${cfg.name}/${b}";
      message = "Job restic-backups-${b}-prune failed.";
      appName = "restic";
      urgency = "critical";
    };
  }) enabledBackends);
in
{
  options.mg.restic = {
    enable = lib.mkEnableOption "the restic backup configuration";

    enableRest = lib.mkEnableOption "the restic REST backend (see restic_rest_url)";
    enableSsh = lib.mkEnableOption "the restic SSH/SFTP backend (see sshUrl, is tightly coupled to my home network)";
    enableLocal = lib.mkEnableOption "the local disk backup backend (see localBackupUuid)";

    passwordPath = lib.mkOption {
      type = lib.types.str;
      description = "Path to a file containing the restic repository password. Can be a sops-nix secret path (e.g. config.sops.secrets.\"restic\".path) or any plain file.";
      example = "config.sops.secrets.\"restic\".path";
    };

    restUrlPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Path to a file containing the REST repository URL. Can be a sops-nix secret path (e.g. config.sops.secrets.\"restic_rest_url\".path) or any plain file. Required when enableRest is true.";
      example = "config.sops.secrets.\"restic_rest_url\".path";
    };

    name = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      description = "Host/machine identifier used in tags, locks and repository paths.";
      example = "mg-laptop";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "mg";
      description = "Backup user; their home directory is used to resolve default excludes and the SSH client identity paths.";
      example = "mg";
    };

    localBackupUuid = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "UUID of the local backup disk (see /dev/disk/by-uuid). Required when enableLocal is true.";
    };

    sshUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "SFTP repository URL, e.g. sftp:user@host:/path/to/repo. Required when enableSsh is true.";
    };

    sshWakeEnabled = lib.mkEnableOption "waking the SSH backup target before a backup";

    notify = {
      channels = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        description = ''
          Default notification channels for all restic failure notifications.
          null inherits mg.notify.defaultChannels. Valid channel names are
          validated by the mg.notify module (e.g. "desktop", "gotify").
        '';
        example = [ "desktop" ];
      };

      perBackend = lib.mkOption {
        type = lib.types.attrsOf (lib.types.listOf lib.types.str);
        default = { };
        description = ''
          Per-backend channel override. The key is a backend name
          (rest/ssh/local) and the value is the channel list to use for that
          backend's backup AND prune jobs. Overrides notify.channels. Use [ ]
          to silence a backend entirely.
        '';
        example = { ssh = [ "desktop" ]; local = [ ]; };
      };
    };

    additionalSources = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra backup sources, e.g. \"/data\".";
    };

    additionalExcludes = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra exclude patterns, e.g. \"/tmp\".";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.enableRest || cfg.restUrlPath != null;
        message = "mg.restic.restUrlPath must be set when mg.restic.enableRest is true.";
      }
      {
        assertion = !cfg.enableSsh || cfg.sshUrl != null;
        message = "mg.restic.sshUrl must be set when mg.restic.enableSsh is true.";
      }
      {
        assertion = !cfg.enableLocal || cfg.localBackupUuid != null;
        message = "mg.restic.localBackupUuid must be set when mg.restic.enableLocal is true.";
      }
    ];

    # One `services.restic.backups.<b>` backup job (daily 08:00) and one
    # `<b>-prune` prune-only job (monthly 1st 12:00) per enabled backend.
    services.restic.backups = lib.optionalAttrs cfg.enableRest {
      rest = {
        repositoryFile = cfg.restUrlPath;
        passwordFile = cfg.passwordPath;
        paths = allSources;
        exclude = allExcludes;
        extraBackupArgs = commonBackupArgs;
        timerConfig = dailyTimer;
        backupPrepareCommand = resticUnlockCmd;
        createWrapper = true;
      };
      "rest-prune" = {
        repositoryFile = cfg.restUrlPath;
        passwordFile = cfg.passwordPath;
        paths = [ ];
        pruneOpts = pruneOptsList;
        timerConfig = monthlyTimer;
        backupPrepareCommand = resticUnlockCmd;
        createWrapper = false;
      };
    } // lib.optionalAttrs cfg.enableSsh {
      ssh = {
        repository = cfg.sshUrl;
        passwordFile = cfg.passwordPath;
        paths = allSources;
        exclude = allExcludes;
        extraBackupArgs = commonBackupArgs;
        timerConfig = dailyTimer;
        backupPrepareCommand = sshPrepare;
        createWrapper = true;
      };
      "ssh-prune" = {
        repository = cfg.sshUrl;
        passwordFile = cfg.passwordPath;
        paths = [ ];
        pruneOpts = pruneOptsList;
        timerConfig = monthlyTimer;
        backupPrepareCommand = sshPrepare;
        createWrapper = false;
      };
    } // lib.optionalAttrs cfg.enableLocal {
      local = {
        repository = "local:/mnt/backup-local-${cfg.name}/backup-restic-${cfg.name}";
        passwordFile = cfg.passwordPath;
        paths = allSources;
        exclude = allExcludes;
        extraBackupArgs = commonBackupArgs;
        timerConfig = dailyTimer;
        backupPrepareCommand = localPrepare;
        createWrapper = true;
      };
      "local-prune" = {
        repository = "local:/mnt/backup-local-${cfg.name}/backup-restic-${cfg.name}";
        passwordFile = cfg.passwordPath;
        paths = [ ];
        pruneOpts = pruneOptsList;
        timerConfig = monthlyTimer;
        backupPrepareCommand = localPrepare;
        createWrapper = false;
      };
    };

    # On-demand mount of the local backup disk. The `.mount` unit is not in
    # local-fs.target (no `wantedBy`), so it only activates when the backup
    # or prune service `Requires` it, and systemd unmounts it again once the
    # service stops. systemd performs the mount with its own environment,
    # avoiding the restricted PATH of the restic service.
    systemd.mounts = lib.mkIf cfg.enableLocal [
      {
        what = "/dev/disk/by-uuid/${cfg.localBackupUuid}";
        where = "/mnt/backup-local-${cfg.name}";
        options = "defaults";
      }
    ];

    # Ensure the mount point exists for the .mount unit (systemd also
    # creates it automatically, but be explicit).
    systemd.tmpfiles.rules = lib.mkIf cfg.enableLocal [
      "d /mnt/backup-local-${cfg.name} 0755 root root - -"
    ];

    # Low IO priority (Nice) for every backend's units.
    systemd.services = lib.mkMerge (map mkServiceOverrides enabledBackends);

    # Failure notifications, handled by the generic notification module.
    mg.notify.onFailure = resticNotifyOnFailure;

    environment.systemPackages = [
      resticp
      sshWakeup
    ];
  };
}
