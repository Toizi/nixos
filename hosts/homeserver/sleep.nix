# Suspend when idle; wake-on-LAN (see default.nix) brings the box back. The
# desktop/laptop backup jobs wake it via the router, so it must not suspend
# while someone is connected or a backup is running.
{ pkgs, ... }:

let
  suspendWhenIdle = pkgs.writeShellApplication {
    name = "suspend-when-idle";
    runtimeInputs = with pkgs; [ systemd iproute2 coreutils gawk ];
    text = ''
      # Stay awake at least this long after boot/resume so a client that just
      # woke us can still connect.
      grace=90

      if [ -n "$(loginctl list-sessions --no-legend)" ]; then
        echo "no sleep: login session"; exit 0
      fi
      if [ -n "$(ss -H -tn state established '( sport = :22 )')" ]; then
        echo "no sleep: ssh connection"; exit 0
      fi
      if systemctl is-active --quiet 'restic*.service'; then
        echo "no sleep: restic running"; exit 0
      fi

      now=$(date +%s)
      up=$(awk '{ print int($1) }' /proc/uptime)
      awake_since=$(( now - up ))
      if [ -e /run/last-resume ]; then
        resumed=$(stat -c %Y /run/last-resume)
        [ "$resumed" -gt "$awake_since" ] && awake_since=$resumed
      fi
      if [ $(( now - awake_since )) -lt "$grace" ]; then
        echo "no sleep: awake for less than ''${grace}s"; exit 0
      fi

      echo "suspending"
      exec systemctl suspend
    '';
  };
in
{
  systemd.services.suspend-when-idle = {
    description = "Suspend when idle";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${suspendWhenIdle}/bin/suspend-when-idle";
    };
  };
  systemd.timers.suspend-when-idle = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "*:0/3";
  };

  # Timestamp of the last resume, read by suspend-when-idle.
  systemd.services.record-resume = {
    description = "Record resume time";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/touch /run/last-resume";
    };
  };
}
