# Headless server (netcup KVM VPS). Shared base comes from ../../modules/common;
# the static IP, authorized SSH keys, secrets and backup targets are added by the
# private flake (nixosModules.vps).
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
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
