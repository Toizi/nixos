# Plex Media Server; library state lives in /var/lib/plex (same path as on the
# previous install), media comes from the rclone mount.
{ ... }:

{
  services.plex.enable = true;

  systemd.services.plex = {
    wants = [ "rclone-media.service" ];
    after = [ "rclone-media.service" ];
  };

  # Direct access (remote streaming); not proxied through Caddy.
  networking.firewall.allowedTCPPorts = [ 32400 ];
}
