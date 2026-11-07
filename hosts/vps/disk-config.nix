# Single disk, GPT, bootable under both BIOS and UEFI (GRUB). Plain ext4, no
# LUKS: the box has to come back from a remote reboot unattended.
# Check the device name with `lsblk` on the target before installing.
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
        ESP = {
          size = "512M";
          type = "EF00";
          priority = 2;
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
