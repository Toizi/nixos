# Headless server. Shared base comes from ../../modules/common; authorized SSH
# keys, secrets and backup targets are added by the private flake (nixosModules.vps).
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  networking.hostName = "mg-vps";

  # GRUB with an EFI removable fallback + BIOS boot partition (see disk-config.nix).
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  # Key-only SSH; keys come from the private flake.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # No password is set for mg (key-only login), so sudo cannot prompt for one.
  security.sudo.wheelNeedsPassword = false;

  system.stateVersion = "26.05";
}
