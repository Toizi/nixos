# Home backup target (sftp repo for the desktop/laptop, wake-on-LAN + suspend on
# idle) that also backs up the Hetzner storage box. Shared base comes from
# ../../modules/common; the static IP, authorized SSH keys, secrets and restic
# targets are added by the private flake (nixosModules.homeserver).
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./sleep.nix
    ./storage.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "mg-homeserver";
  networking.useDHCP = false; # address/gateway are static, see private flake
  # Magic-packet wake (from the router's ether-wake, also after suspend).
  networking.interfaces.enp3s0.wakeOnLan.enable = true;

  zramSwap.enable = true;

  # btrfs RAID1 of sdb (whole disk) + sdc1, pool UUID covers both members. Not
  # `degraded`: a missing member must fail the mount instead of silently running
  # on one disk. `nofail` keeps the box reachable over ssh if the pool is broken.
  fileSystems."/backup" = {
    device = "/dev/disk/by-uuid/738c18cf-149e-462f-b78b-8e187b2845c3";
    fsType = "btrfs";
    options = [ "subvol=@backup" "compress=zstd" "noatime" "nofail" ];
  };

  # Key-only SSH, no root login (keys come from the private flake).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Passwords come from sops (users.users.mg.hashedPasswordFile in the private
  # flake); NixOS only applies them to existing users when users are immutable.
  users.mutableUsers = false;

  # Failure/heartbeat notifications go out via Gotify (channel enabled by the
  # private flake, which supplies the push URL).
  mg.notify.defaultChannels = [ "gotify" ];

  # Weekly heartbeat proving that notifications still reach a phone.
  systemd.services.gotify-heartbeat = {
    description = "Heartbeat for gotify notifications";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/mg-notify --priority 5 --title \"Heartbeat mg-homeserver\" --message \"Notifications are working for mg-homeserver\"";
    };
  };
  systemd.timers.gotify-heartbeat = {
    wantedBy = [ "timers.target" ];
    timerConfig.OnCalendar = "Sun 18:00";
  };

  system.stateVersion = "26.05";
}
