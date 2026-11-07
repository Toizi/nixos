# KVM guest (QEMU i440FX, virtio-scsi disk, virtio-net), BIOS boot.
# Values taken from the running Arch install (lspci, lsblk).
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ata_piix" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
