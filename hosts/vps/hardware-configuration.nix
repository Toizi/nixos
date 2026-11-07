# Generic KVM/QEMU guest. Verify against `nixos-generate-config` output on the
# target (nixos-anywhere can generate it: --generate-hardware-config).
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
