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

  # No password is set for mg (key-only login), so sudo cannot prompt for one.
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
