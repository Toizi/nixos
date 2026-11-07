{ config, lib, pkgs, ... }:

{
  imports = [
    ../../modules/desktop
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # linuxPackages_latest tracks 7.3; tuxedo-drivers 4.20.1 doesn't compile
  # against it (clevo_acpi uses ACPI interfaces removed in 7.3). Pin 7.2.
  boot.kernelPackages = pkgs.linuxPackages_7_2.extend (self: super: {
    # tuxedo-drivers' Makefile puts $(MAKEFLAGS) on a shell line; the kernel
    # module sign hook's `cmd_sign=…$(space)$@` then reaches bash unquoted and
    # dies with "syntax error near unexpected token `('". Letting make relay
    # flags via the environment (the default) keeps signing working.
    tuxedo-drivers = super.tuxedo-drivers.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace Makefile \
          --replace-fail 'M=$(PWD) $(MAKEFLAGS) modules' 'M=$(PWD) modules'
      '';
    });
  });

  networking.hostName = "mg-laptop"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  services.udev.extraHwdb = ''
    # matches all AT keyboards (laptop keyboard)
    #   capslock = left ctrl
    #   left ctrl = escape
    #   esc = capslock
    #   win = alt
    #   alt = win
    evdev:atkbd:dmi:bvn*:bvr*:bd*:svn*:pn*:pvr*
      KEYBOARD_KEY_01=capslock
      KEYBOARD_KEY_3a=leftctrl
      KEYBOARD_KEY_1d=esc
      KEYBOARD_KEY_db=leftalt
      KEYBOARD_KEY_38=leftmeta
  '';

  hardware.bluetooth = {
    enable = true;
  };
  services.blueman.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

  services.getty = {
    autologinUser = "mg";
    autologinOnce = true;
  };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # Open ports in the firewall for Syncthing. (NOTE: this will not open syncthing gui port)
    user = "mg";
    dataDir = "/home/mg/data";
    configDir = "/home/mg/.config/syncthing";
  };

  hardware.tuxedo-rs = {
    enable = true;
    tailor-gui.enable = true;
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "26.05"; # Did you read the comment?
}
