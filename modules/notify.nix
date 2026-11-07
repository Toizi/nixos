# Generic notification system (mg.notify).
#
# Extracted from the restic backup module so any service can send
# notifications. Provides:
#
#   * `mg-notify`        — a channel-agnostic CLI that fans a notification out
#                          to every enabled channel (desktop + Gotify).
#   * `root-notify-send` — desktop (libnotify) notification routed to the
#                          active graphical session (Wayland/X11 agnostic).
#   * `gotify-send`      — Gotify push notification via curl.
#   * `mg.notify.onFailure` — a declarative option to attach a failure
#                          notification to any systemd unit; it generates the
#                          oneshot notifier service and wires the target unit's
#                          `OnFailure` automatically.
#
# Enable the module with `mg.notify.enable`, then turn on the channels you
# want (`mg.notify.desktop.enable`, `mg.notify.gotify.enable`). Other modules
# only need to populate `mg.notify.onFailure` (or call `mg-notify` directly).
{ config, lib, pkgs, ... }:

let
  cfg = config.mg.notify;

  bool = lib.boolToString;

  # Canonical set of notification channels. Adding a new channel means: add its
  # `mg.notify.<chan>` enable block, add its name here, and teach `mg-notify`
  # one more `--no-<chan>` flag — no churn in onFailure entries or consumers.
  channelNames = [ "desktop" "gotify" ];

  # Channels that are globally switched on (the master gates).
  enabledChannels = lib.optional cfg.desktop.enable "desktop"
    ++ lib.optional cfg.gotify.enable "gotify";

  # The channels an entry can actually reach: its own list intersected with the
  # globally-enabled channels.
  activeChannels = v: lib.intersectLists v.channels enabledChannels;

  # Desktop (libnotify) notification routed to the active user's session bus,
  # so it works on both Wayland and X11. App name / urgency / fallback user
  # are read from the environment so the same binary is reusable.
  rootNotifySend = pkgs.writeShellScriptBin "root-notify-send" ''
    title="$1"
    message="$2"
    [ -z "$title" ] && exit 0

    app_name="''${NOTIFY_APP_NAME:-system}"
    urgency="''${NOTIFY_URGENCY:-normal}"
    fallback_user="''${NOTIFY_FALLBACK_USER:-${cfg.desktop.user}}"

    user="$(
      ${pkgs.systemd}/bin/loginctl list-sessions --no-legend 2>/dev/null | while read -r id _; do
        [ -n "$id" ] && ${pkgs.systemd}/bin/loginctl show-session "$id" -p Name --value 2>/dev/null && break
      done | head -n1
    )"
    [ -z "$user" ] && user="$fallback_user"
    uid="$(id -u "$user" 2>/dev/null || echo 1000)"

    exec ${pkgs.util-linux}/bin/runuser -u "$user" -- env \
      DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
      ${pkgs.libnotify}/bin/notify-send --app-name="$app_name" --urgency="$urgency" "$title" "$message"
  '';

  # Gotify push notification. URL read from GOTIFY_URL_FILE (configurable),
  # falling back to the module's gotify.urlPath default.
  gotifySend = pkgs.writeShellScriptBin "gotify-send" ''
    priority="$1"
    title="$2"
    message="$3"
    url_file="''${GOTIFY_URL_FILE:-${toString cfg.gotify.urlPath}}"
    [ -r "$url_file" ] || { echo "gotify-send: cannot read $url_file" >&2; exit 1; }
    url="$(cat "$url_file")"

    exec ${pkgs.curl}/bin/curl -fsS -X POST "$url" \
      -F "title=$title" -F "message=$message" -F "priority=$priority"
  '';

  # Channel-agnostic dispatcher. Globally enabled channels are baked in at
  # build time; per-invocation flags can still narrow them (--no-desktop /
  # --no-gotify) or tune presentation (--priority / --app-name / --urgency).
  mgNotify = pkgs.writeShellScriptBin "mg-notify" ''
    set -u

    desktop=${bool cfg.desktop.enable}
    gotify=${bool cfg.gotify.enable}
    priority=${toString cfg.gotify.defaultPriority}
    app_name="system"
    urgency="normal"
    title=""
    message=""

    export GOTIFY_URL_FILE="''${GOTIFY_URL_FILE:-${toString cfg.gotify.urlPath}}"

    usage() {
      cat >&2 <<'EOF'
    Usage: mg-notify --title TITLE [options]
           mg-notify TITLE [MESSAGE]

    Options:
      -t, --title TEXT      Notification title (required)
      -m, --message TEXT    Notification body
      -p, --priority N      Gotify priority (default: baked-in)
      -a, --app-name NAME   Desktop app name (default: system)
      -u, --urgency LEVEL   Desktop urgency: low|normal|critical
          --no-desktop      Skip the desktop channel for this call
          --no-gotify       Skip the Gotify channel for this call
      -h, --help            Show this help
    EOF
    }

    while [ "$#" -gt 0 ]; do
      case "$1" in
        -t|--title)     title="$2"; shift 2 ;;
        -m|--message)   message="$2"; shift 2 ;;
        -p|--priority)  priority="$2"; shift 2 ;;
        -a|--app-name)  app_name="$2"; shift 2 ;;
        -u|--urgency)   urgency="$2"; shift 2 ;;
        --no-desktop)   desktop=false; shift ;;
        --no-gotify)    gotify=false; shift ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; break ;;
        -*)             echo "mg-notify: unknown option $1" >&2; usage; exit 2 ;;
        *)              break ;;
      esac
    done

    # Positional fallback: TITLE [MESSAGE]
    [ -z "$title" ] && [ "$#" -gt 0 ] && { title="$1"; shift; }
    [ -z "$message" ] && [ "$#" -gt 0 ] && { message="$1"; shift; }

    if [ -z "$title" ]; then
      echo "mg-notify: --title is required" >&2
      usage
      exit 2
    fi

    rc=0
    if [ "$desktop" = "true" ]; then
      NOTIFY_APP_NAME="$app_name" NOTIFY_URGENCY="$urgency" \
        ${rootNotifySend}/bin/root-notify-send "$title" "$message" || rc=$?
    fi
    if [ "$gotify" = "true" ]; then
      ${gotifySend}/bin/gotify-send "$priority" "$title" "$message" || rc=$?
    fi
    exit "$rc"
  '';

  # Sanitize an arbitrary systemd unit name into a safe oneshot service name.
  notifyUnitName = unit:
    "notify-fail-" + lib.replaceStrings [ "/" "@" ":" "\\" "." " " ] [ "-" "-" "-" "-" "-" "-" ] unit;

  # Build the oneshot notifier service value for one onFailure entry.
  mkFailService = unit: v: {
    description = "Failure notification for ${unit}";
    serviceConfig.Type = "oneshot";
    path = [ mgNotify ];
    script = ''
      exec ${mgNotify}/bin/mg-notify \
        --app-name ${lib.escapeShellArg v.appName} \
        --urgency ${lib.escapeShellArg v.urgency} \
        --priority ${toString v.priority} \
        ${lib.optionalString (!(lib.elem "desktop" v.channels)) "--no-desktop"} \
        ${lib.optionalString (!(lib.elem "gotify" v.channels)) "--no-gotify"} \
        --title ${lib.escapeShellArg v.title} \
        --message ${lib.escapeShellArg v.message}
    '';
  };

  # Only generate notifier services / wire OnFailure for entries that have at
  # least one reachable channel (entry channels intersected with the globally
  # enabled ones). This subsumes a global "any channel enabled?" gate.
  failureUnits = lib.mapAttrsToList (unit: v: {
    "${notifyUnitName unit}" = mkFailService unit v;
    "${unit}".onFailure = [ "${notifyUnitName unit}.service" ];
  }) (lib.filterAttrs (_: v: activeChannels v != [ ]) cfg.onFailure);
in
{
  options.mg.notify = {
    enable = lib.mkEnableOption "the generic notification system (mg-notify)";

    defaultChannels = lib.mkOption {
      type = lib.types.listOf (lib.types.enum channelNames);
      default = channelNames;
      description = ''
        Default channel set for onFailure entries that do not set their own
        `channels`. The effective channels for any entry are still intersected
        with the globally-enabled channels (desktop.enable / gotify.enable).
      '';
    };

    desktop = {
      enable = lib.mkEnableOption "desktop notifications via libnotify";
      user = lib.mkOption {
        type = lib.types.str;
        default = "mg";
        description = ''
          Fallback user whose graphical session receives desktop
          notifications. The active session is discovered via loginctl; this
          user is used when no session can be found.
        '';
        example = "mg";
      };
    };

    gotify = {
      enable = lib.mkEnableOption "Gotify push notifications";
      urlPath = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file containing the Gotify push URL, read by gotify-send
          via the GOTIFY_URL_FILE env var. Required when gotify.enable is true.
        '';
        example = "/home/mg/data/secrets/gotify_url";
      };
      defaultPriority = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Default Gotify priority when a caller does not set one.";
      };
    };

    onFailure = lib.mkOption {
      default = { };
      description = ''
        Declarative failure notifications. Each attribute name is a systemd
        unit to watch; when it fails, a generated oneshot notifier service is
        triggered via the unit's OnFailure and sends the configured message
        through the entry's channels (intersected with the globally-enabled
        channels). Any unit can be overridden directly, e.g.
        `mg.notify.onFailure."restic-backups-ssh".channels = [ "desktop" ];`.
      '';
      example = lib.literalExpression ''
        {
          "my-service" = {
            title = "my-service failed on $(hostname)";
            message = "Check journalctl -u my-service.";
            urgency = "critical";
          };
        }
      '';
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          title = lib.mkOption {
            type = lib.types.str;
            description = "Notification title.";
          };
          message = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Notification body.";
          };
          priority = lib.mkOption {
            type = lib.types.int;
            default = cfg.gotify.defaultPriority;
            description = "Gotify priority for this notification.";
          };
          appName = lib.mkOption {
            type = lib.types.str;
            default = "system";
            description = "Desktop app name shown in the notification.";
          };
          urgency = lib.mkOption {
            type = lib.types.enum [ "low" "normal" "critical" ];
            default = "critical";
            description = "Desktop notification urgency.";
          };
          channels = lib.mkOption {
            type = lib.types.listOf (lib.types.enum channelNames);
            default = cfg.defaultChannels;
            description = ''
              Channels this notification may use. The effective set is these
              intersected with the globally-enabled channels
              (desktop.enable / gotify.enable). Set to [ ] to silence this
              notification entirely.
            '';
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = !cfg.gotify.enable || cfg.gotify.urlPath != null;
          message = "mg.notify.gotify.urlPath must be set when mg.notify.gotify.enable is true.";
        }
      ];

      environment.systemPackages = [ mgNotify rootNotifySend gotifySend ];

      # Generated notifier services + OnFailure wiring. `failureUnits` already
      # filters out entries with no reachable channel, so this is empty when
      # nothing is enabled.
      systemd.services = lib.mkMerge failureUnits;
    }
  ]);
}
