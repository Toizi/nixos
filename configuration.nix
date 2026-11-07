# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "spotify"
  ];
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./disk-config.nix
      ./notify.nix
      ./restic-backup.nix
    ];

  # Restic backup targets, sops secrets and gotify come from the private flake
  # (nixos-private); see mg.restic / mg.notify options in restic-backup.nix and
  # notify.nix.
  mg.notify = {
    enable = true;
    desktop.enable = true;
    defaultChannels = [ "desktop" ];
  };

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

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

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

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
  };
  services.blueman.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.mg = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;
  programs.zsh.enable = true;
  users.users.mg.shell = pkgs.zsh;

  # create /bin/bash symlink to make common shebangs work
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    openssl
    stdenv.cc.cc
  ];

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    unzip
    git
    jq
    file
    python3
    uv
    brightnessctl
    ungoogled-chromium
    pavucontrol
    bubblewrap

    # notifications
    gotify-cli
    libnotify
    dunst

    # backups
    restic
    fuse
    sops
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

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

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

