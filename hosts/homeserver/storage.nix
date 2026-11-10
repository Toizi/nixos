# Backup of the Hetzner storage box (read-only rclone mount) into the local
# /backup/restic-storage repository. The rclone config and repo password come
# from the private flake (mg.rclone.configFile, mg.homeserver.storageBackupPasswordFile).
{ config, lib, pkgs, ... }:

let
  cfg = config.mg.homeserver;

  mountPoint = "/mnt/storage";
  rcPort = 5572;

  # Directories of the share that are backed up; each is refreshed in the rclone
  # VFS dir cache before a run so new files are seen.
  dirs = [
    "data"
    "photos/immich/backups"
    "photos/immich/upload"
    "backups/backup-restic-vps"
  ];

  repository = "/backup/restic-storage";
  resticBin = "${pkgs.restic}/bin/restic";
  rclone = lib.getExe pkgs.rclone;

  prepare = lib.concatStringsSep "\n" (
    [ "${resticBin} unlock" ]
    ++ map (d: "${rclone} rc vfs/refresh recursive=true --timeout 30m --url 127.0.0.1:${toString rcPort} dir=${d}") dirs
  );

  # Snapshots from the Arch install carry host "mg-server" and tag "homeserver".
  # Keeping both stops restic from treating the new hostname as a new host (no
  # parent snapshot => rereads the whole 280 GiB share) and keeps retention
  # matching the existing snapshots.
  host = "mg-server";
  tag = "homeserver";

  # Same policy as the other hosts (modules/restic-backup.nix).
  pruneOpts = [
    "--keep-hourly" "1"
    "--keep-daily" "3"
    "--keep-weekly" "2"
    "--keep-monthly" "6"
    "--keep-tag" "forever"
    "--host" host
    "--tag" tag
    "--tag" "full"
    "--retry-lock" "2h"
  ];

  # Needs the repo disk and the mount; without these a run would write to the
  # root SSD or back up an empty directory.
  unitDeps = {
    requires = [ "rclone-storage.service" ];
    after = [ "rclone-storage.service" ];
    unitConfig.RequiresMountsFor = [ "/backup" ];
    serviceConfig.Nice = 19;
  };
in
{
  imports = [ ../../modules/rclone-mounts.nix ];

  options.mg.homeserver.storageBackupPasswordFile = lib.mkOption {
    type = lib.types.path;
    description = "File with the password of the restic repository at ${repository}.";
  };

  config = {
    mg.rclone.mounts.storage = {
      remote = "storage:";
      inherit mountPoint rcPort;
      readOnly = true;
      extraArgs = [
        "--vfs-cache-max-size" "1G"
        "--vfs-fast-fingerprint"
        "--dir-cache-time" "1h"
      ];
    };

    services.restic.backups = {
      storage = {
        inherit repository;
        passwordFile = cfg.storageBackupPasswordFile;
        paths = map (d: "${mountPoint}/${d}") dirs;
        extraBackupArgs = [
          "--exclude-caches"
          "--one-file-system"
          "--host" host
          "--tag" tag
          "--tag" "full"
          "--retry-lock" "2h"
        ];
        timerConfig = { OnCalendar = "08:00:00"; Persistent = true; };
        backupPrepareCommand = prepare;
      };
      storage-prune = {
        inherit repository pruneOpts;
        passwordFile = cfg.storageBackupPasswordFile;
        paths = [ ];
        timerConfig = { OnCalendar = "*-*-01 12:00:00"; Persistent = true; };
        backupPrepareCommand = "${resticBin} unlock";
      };
    };

    systemd.services.restic-backups-storage = unitDeps;
    systemd.services.restic-backups-storage-prune = unitDeps // {
      requires = [ ];
      after = [ ];
    };

    mg.notify.onFailure = {
      "restic-backups-storage" = {
        title = "restic backup failed: ${config.networking.hostName}/storage";
        message = "Job restic-backups-storage failed.";
        appName = "restic";
        urgency = "critical";
      };
      "restic-backups-storage-prune" = {
        title = "restic prune failed: ${config.networking.hostName}/storage";
        message = "Job restic-backups-storage-prune failed.";
        appName = "restic";
        urgency = "critical";
      };
    };
  };
}
