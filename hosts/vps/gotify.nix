# Gotify push server (behind Caddy) and a weekly heartbeat proving that
# notifications still reach a phone.
{ config, ... }:

{
  services.gotify = {
    enable = true;
    environment = {
      GOTIFY_SERVER_LISTENADDR = "127.0.0.1";
      GOTIFY_SERVER_PORT = 3001;
    };
  };

  systemd.services.gotify-heartbeat = {
    description = "Heartbeat for gotify notifications";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" "gotify-server.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/mg-notify --priority 5 --title \"Heartbeat ${config.networking.hostName}\" --message \"Notifications are working for ${config.networking.hostName}\"";
    };
  };
  systemd.timers.gotify-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "Sun 18:00";
  };
}
