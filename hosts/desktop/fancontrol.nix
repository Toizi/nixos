# Case/radiator fans on the board's Nuvoton NCT6797, driven by lm_sensors'
# `fancontrol` (GPU fans are handled by LACT, see default.nix).
#
# hwmon indices are not stable across boots, which breaks the stock
# hardware.fancontrol (it validates DEVPATH/DEVNAME against fixed hwmonN).
# So the config is generated at service start, resolving chips by name.
#
# fancontrol ramps linearly: minPwm at/below minTemp, maxPwm at/above maxTemp.
# minStop = minPwm, so a fan never stops. Ported from the old fan2go setup.
{ lib, pkgs, ... }:

let
  chips = {
    board = "nct6797";
    cpu = "k10temp";
  };

  fans = [
    # pwm = header number. temp = { chip, input } sensor. Temps in °C, pwm 0-255.
    { pwm = 1; temp = { chip = "board"; input = "temp2_input"; }; minTemp = 40; maxTemp = 80; minPwm = 63; maxPwm = 100; } # CPU header (AIO)
    { pwm = 2; temp = { chip = "cpu"; input = "temp1_input"; }; minTemp = 45; maxTemp = 80; minPwm = 60; maxPwm = 255; }
    { pwm = 4; temp = { chip = "board"; input = "temp2_input"; }; minTemp = 40; maxTemp = 80; minPwm = 63; maxPwm = 255; } # top back
    { pwm = 5; temp = { chip = "board"; input = "temp2_input"; }; minTemp = 40; maxTemp = 80; minPwm = 63; maxPwm = 255; } # back
    { pwm = 6; temp = { chip = "board"; input = "temp2_input"; }; minTemp = 40; maxTemp = 80; minPwm = 63; maxPwm = 255; } # top front
    { pwm = 7; temp = { chip = "board"; input = "temp2_input"; }; minTemp = 40; maxTemp = 80; minPwm = 40; maxPwm = 80; }  # mainboard small
  ];

  fanLines = f:
    let
      n = toString f.pwm;
      key = "$BOARD/pwm${n}";
      tempVar = "$" + lib.toUpper f.temp.chip;
    in ''
      FCTEMPS="$FCTEMPS ${key}=${tempVar}/${f.temp.input}"
      FCFANS="$FCFANS ${key}=$BOARD/fan${n}_input"
      MINTEMP="$MINTEMP ${key}=${toString f.minTemp}"
      MAXTEMP="$MAXTEMP ${key}=${toString f.maxTemp}"
      MINSTART="$MINSTART ${key}=${toString f.minPwm}"
      MINSTOP="$MINSTOP ${key}=${toString f.minPwm}"
      MINPWM="$MINPWM ${key}=${toString f.minPwm}"
      MAXPWM="$MAXPWM ${key}=${toString f.maxPwm}"
    '';

  script = pkgs.writeShellScript "fancontrol-nct6797" ''
    set -eu
    hwmon() {
      for d in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$d/name")" = "$1" ]; then basename "$d"; return; fi
      done
      echo "fancontrol: no hwmon chip named $1" >&2
      exit 1
    }
    devpath() { ${pkgs.coreutils}/bin/readlink -f "/sys/class/hwmon/$1/device" | ${pkgs.gnused}/bin/sed 's|^/sys/||'; }

    BOARD=$(hwmon ${chips.board})
    CPU=$(hwmon ${chips.cpu})
    FCTEMPS= FCFANS= MINTEMP= MAXTEMP= MINSTART= MINSTOP= MINPWM= MAXPWM=
    ${lib.concatMapStrings fanLines fans}
    conf=/run/fancontrol/fancontrol.conf
    mkdir -p /run/fancontrol
    {
      echo "INTERVAL=5"
      echo "DEVPATH=$BOARD=$(devpath "$BOARD") $CPU=$(devpath "$CPU")"
      echo "DEVNAME=$BOARD=${chips.board} $CPU=${chips.cpu}"
      echo "FCTEMPS=$FCTEMPS"
      echo "FCFANS=$FCFANS"
      echo "MINTEMP=$MINTEMP"
      echo "MAXTEMP=$MAXTEMP"
      echo "MINSTART=$MINSTART"
      echo "MINSTOP=$MINSTOP"
      echo "MINPWM=$MINPWM"
      echo "MAXPWM=$MAXPWM"
    } > "$conf"
    exec ${pkgs.lm_sensors}/bin/fancontrol "$conf"
  '';
in
{
  boot.kernelModules = [ "nct6775" ];

  systemd.services.fancontrol = {
    description = "Case fan control (fancontrol, nct6797)";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    path = [ pkgs.coreutils pkgs.gnused pkgs.gawk pkgs.bash ];
    serviceConfig = {
      ExecStart = script;
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
