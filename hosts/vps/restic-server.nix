# restic REST server serving the rclone-mounted /backups, behind Caddy.
# Auth uses /backups/.htpasswd (lives on the storage box, not managed here).
{ config, lib, pkgs, ... }:

let
  ordering = {
    wants = [ "restic-rest-server.service" "caddy.service" ];
    after = [ "restic-rest-server.service" "caddy.service" ];
  };
in
{
  users.users.backupboi = {
    isSystemUser = true;
    group = "backupboi";
  };
  users.groups.backupboi = { };

  systemd.services.restic-rest-server = {
    description = "restic REST server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "rclone-backups.service" ];
    requires = [ "rclone-backups.service" ];
    serviceConfig = {
      Type = "simple";
      User = "backupboi";
      Group = "backupboi";
      ExecStartPre = "${pkgs.util-linux}/bin/mountpoint -q /backups";
      ExecStart = "${lib.getExe' pkgs.restic-rest-server "rest-server"} --path /backups --listen 127.0.0.1:3002";
      Restart = "always";
      RestartSec = 5;

      ReadWritePaths = [ "/backups" ];
      UMask = "0027";
      CapabilityBoundingSet = "";
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      ProtectHostname = true;
      RemoveIPC = true;
      RestrictNamespaces = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictSUIDSGID = true;
      RestrictRealtime = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [ "@system-service" ];
    };
  };

  # The VPS backs itself up to its own REST server (through Caddy), so the
  # backup/prune jobs must come after both are up.
  systemd.services.restic-backups-rest = lib.mkIf (config.mg.restic.enable && config.mg.restic.enableRest) ordering;
  systemd.services.restic-backups-rest-prune = lib.mkIf (config.mg.restic.enable && config.mg.restic.enableRest) ordering;
}
