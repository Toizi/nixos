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

  # Remote clients sit behind a lossy home link (~1% retransmits observed);
  # cubic collapses its window on every loss, BBR does not.
  boot.kernel.sysctl = {
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
}
