# Declarative rclone FUSE mounts (mg.rclone).
#
# Each entry in `mg.rclone.mounts` becomes a `rclone-<name>.service` that mounts
# `remote` at `mountPoint` as the unprivileged `mg.rclone.user`, with the rc API
# bound to 127.0.0.1:<rcPort> (used for `vfs/refresh` after startup and by
# other units, e.g. `rclone rc vfs/refresh --url 127.0.0.1:<rcPort>`).
#
# The rclone config file holds credentials, so it is passed in as a path
# (typically a sops-nix secret owned by `mg.rclone.user`), never inlined.
{ config, lib, pkgs, ... }:

let
  cfg = config.mg.rclone;

  mountType = lib.types.submodule {
    options = {
      remote = lib.mkOption {
        type = lib.types.str;
        description = "rclone remote (and optional path) to mount, e.g. `media:` or `backups:sub/dir`.";
        example = "media:";
      };
      mountPoint = lib.mkOption {
        type = lib.types.path;
        description = "Directory to mount at. Created (owned by the rclone user) if missing.";
        example = "/mediastorage";
      };
      rcPort = lib.mkOption {
        type = lib.types.port;
        description = "Port of the rc API (bound to 127.0.0.1), unique per mount.";
      };
      readOnly = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Mount read-only.";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra `rclone mount` arguments (VFS cache tuning etc.).";
        example = [ "--vfs-cache-max-size" "2G" ];
      };
    };
  };

  mkMount = name: m:
    let
      rc = "127.0.0.1:${toString m.rcPort}";
      args = [
        "--allow-other"
        "--poll-interval" "10s"
        "--umask" "002"
        "--rc"
        "--rc-addr" rc
        "--rc-no-auth"
        "--cache-dir" "/var/cache/rclone-${name}"
        "--vfs-cache-mode" "full"
        "--bwlimit-file" "60M"
      ] ++ lib.optional m.readOnly "--read-only" ++ m.extraArgs;
    in
    lib.nameValuePair "rclone-${name}" {
      description = "rclone mount ${m.remote} at ${m.mountPoint}";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      # fusermount3 is the setuid wrapper from programs.fuse.
      path = [ "/run/wrappers" ];
      environment.RCLONE_CONFIG = toString cfg.configFile;
      serviceConfig = {
        Type = "notify";
        User = cfg.user;
        Group = cfg.user;
        CacheDirectory = "rclone-${name}";
        ExecStart = "${lib.getExe pkgs.rclone} mount ${lib.escapeShellArg m.remote} ${lib.escapeShellArg (toString m.mountPoint)} ${lib.escapeShellArgs args}";
        ExecStartPost = "-${lib.getExe pkgs.rclone} rc vfs/refresh recursive=true --url ${rc} _async=true";
        ExecStop = "/run/wrappers/bin/fusermount3 -uz ${lib.escapeShellArg (toString m.mountPoint)}";
        Restart = "on-failure";
        RestartSec = 5;
      };
    };
in
{
  options.mg.rclone = {
    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "rclone.conf readable by `mg.rclone.user`; required when any mount is defined.";
      example = lib.literalExpression ''config.sops.secrets."rclone_conf".path'';
    };
    user = lib.mkOption {
      type = lib.types.str;
      default = "rclone";
      description = "User (and group) the mounts and rclone helper units run as.";
    };
    mounts = lib.mkOption {
      type = lib.types.attrsOf mountType;
      default = { };
      description = "rclone mounts, keyed by name (unit `rclone-<name>.service`).";
    };
  };

  config = lib.mkIf (cfg.mounts != { }) {
    assertions = [
      {
        assertion = cfg.configFile != null;
        message = "mg.rclone.configFile must be set when mg.rclone.mounts is non-empty.";
      }
    ];

    programs.fuse = {
      enable = true;
      userAllowOther = true;
    };

    users.users.${cfg.user} = {
      isSystemUser = true;
      group = cfg.user;
    };
    users.groups.${cfg.user} = { };

    systemd.tmpfiles.rules = lib.mapAttrsToList
      (_: m: "d ${toString m.mountPoint} 0755 ${cfg.user} ${cfg.user} -")
      cfg.mounts;

    systemd.services = lib.mapAttrs' mkMount cfg.mounts;
  };
}
