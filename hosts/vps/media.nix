# Remote storage mounts (read-only media, restic backups) and the media sync job.
# Remote names (media, backups, mediasrc, mediastorage) refer to sections of the
# rclone.conf supplied by the private flake via mg.rclone.configFile.
{ config, lib, pkgs, ... }:

{
  imports = [ ../../modules/rclone-mounts.nix ];

  mg.rclone.mounts = {
    media = {
      remote = "media:";
      mountPoint = "/mediastorage";
      rcPort = 5572;
      readOnly = true;
      extraArgs = [
        "--vfs-cache-poll-interval" "1m"
        "--vfs-fast-fingerprint"
      ];
    };
    backups = {
      remote = "backups:";
      mountPoint = "/backups";
      rcPort = 5573;
      extraArgs = [
        "--vfs-cache-max-size" "2G"
        "--vfs-cache-max-age" "5000h"
        "--vfs-cache-poll-interval" "5m"
        "--no-checksum"
      ];
    };
  };

  # Copy new media from the seedbox (mediasrc) to the storage box every 10 min,
  # then make the read-only mount notice it.
  systemd.services.sync-media = {
    description = "Sync media from mediasrc to mediastorage";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    environment.RCLONE_CONFIG = toString config.mg.rclone.configFile;
    serviceConfig = {
      Type = "oneshot";
      User = config.mg.rclone.user;
      Group = config.mg.rclone.user;
      ExecStart = "${lib.getExe pkgs.rclone} copy -v mediasrc:media mediastorage:";
      ExecStartPost = "-${lib.getExe pkgs.rclone} rc vfs/refresh recursive=true --url 127.0.0.1:${toString config.mg.rclone.mounts.media.rcPort} _async=true";
    };
  };
  systemd.timers.sync-media = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:5/10";
  };

  mg.notify.onFailure."sync-media" = {
    title = "media sync failed on $(hostname)";
    message = "Check journalctl -u sync-media.";
    appName = "sync-media";
  };
}
