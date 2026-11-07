# /dev/sda (200G virtio-scsi), BIOS machine: GPT with a BIOS boot partition for
# GRUB, then btrfs with the same subvolume layout as the laptop. No LUKS: the
# box has to come back from a remote reboot unattended.
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02"; # BIOS boot partition for GRUB
          priority = 1;
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            subvolumes = {
              "/root" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "/nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
