{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/desktop
    ./hardware-configuration.nix
    ./disk-config.nix
    ./fancontrol.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Windows lives on its own disk/ESP; pick it from the firmware boot menu.

  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Unlock the full amdgpu power-play feature set (needed for LACT fan/power control).
  boot.kernelParams = [ "amdgpu.ppfeaturemask=0xfffd7fff" ];

  networking.hostName = "mg-desktop";
  networking.networkmanager.enable = true;

  # Bulk data disk (hosts /space/backup). Referenced by UUID; never formatted by disko.
  fileSystems."/space" = {
    device = "/dev/disk/by-uuid/71993a89-f859-4ae9-a720-63255113fc6c";
    fsType = "ext4";
    options = [ "noatime" "nofail" ];
  };

  zramSwap.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # GPU fans/curve; case fans are in ./fancontrol.nix. Written as plain YAML
  # instead of services.lact.settings: LACT needs the curve keys as integers,
  # which the generated YAML would quote as strings.
  services.lact.enable = true;
  environment.etc."lact/config.yaml".text = ''
    version: 7
    daemon:
      log_level: info
      admin_group: wheel
      disable_clocks_cleanup: false
    apply_settings_timer: 5
    gpus:
      1002:747E-148C:2427-0000:2f:00.0:
        fan_control_enabled: true
        fan_control_settings:
          mode: curve
          static_speed: 0.5
          temperature_key: edge
          interval_ms: 500
          curve:
            40: 0.3
            50: 0.35
            60: 0.5
            70: 0.75
            80: 1.0
          spindown_delay_ms: 5000
          change_threshold: 2
        pmfw_options:
          zero_rpm: true
          zero_rpm_threshold: 40
        performance_level: auto
  '';

  # shift+space -> underscore
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.shift.space = "_";
    };
  };

  # Key-only SSH (same policy as the vps).
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  users.users.mg.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLerCZpdcOBZPC8SLjZk97tAf6W1APXGNE/ntXjVqFA mg desktop access"
  ];

  services.getty = {
    autologinUser = "mg";
    autologinOnce = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = "mg";
    dataDir = "/home/mg/data";
    configDir = "/home/mg/.config/syncthing";
  };

  system.stateVersion = "26.05";
}
