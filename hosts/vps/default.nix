# Headless server. Shared base comes from ../../modules/common; the static IP,
# authorized SSH keys, secrets and the base domain are added by the private flake
# (nixosModules.vps).
{ lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
    ./caddy.nix
    ./media.nix
    ./restic-server.nix
    ./plex.nix
    ./gotify.nix
    ./syncthing.nix
    ./open-webui.nix
    ./authelia.nix
  ];

  # Failure/heartbeat notifications go out via Gotify (channel enabled by the
  # private flake, which supplies the push URL).
  mg.notify.defaultChannels = [ "gotify" ];

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "plexmediaserver"
    "open-webui"
  ];

  networking.hostName = "mg-vps";
  networking.useDHCP = false; # address/gateway are static, see private flake

  # BIOS machine; disko's EF02 partition supplies the GRUB device.
  boot.loader.grub.enable = true;

  zramSwap.enable = true;

  virtualisation.docker.enable = true;
  # Docker's published ports bypass the NixOS firewall (DNAT + FORWARD chain), so
  # bind them to loopback unless a container explicitly asks for 0.0.0.0.
  virtualisation.docker.daemon.settings.ip = "127.0.0.1";

  # Key-only SSH, no root login (same policy as the Arch install). Keys come
  # from the private flake.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Ban hosts that repeatedly fail SSH auth (the default sshd jail is enabled
  # automatically with openssh). Bans escalate for repeat offenders.
  services.fail2ban = {
    enable = true;
    maxretry = 5;
    bantime = "1h";
    bantime-increment = {
      enable = true;
      maxtime = "48h";
    };
  };

  # Passwords come from sops (users.users.mg.hashedPasswordFile in the private
  # flake); NixOS only applies them to existing users when users are immutable.
  users.mutableUsers = false;

  system.stateVersion = "26.05";
}
