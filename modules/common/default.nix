# Shared by every host: nix settings, the mg user, base CLI packages.
{ config, lib, pkgs, ... }:

{
  imports = [
    ../notify.nix
    ../restic-backup.nix
  ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [
      "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
    ];
  };

  # Host-specific restic targets, sops secrets and gotify come from the private
  # flake (nixos-private); see mg.restic / mg.notify in ../restic-backup.nix and
  # ../notify.nix. Channels default to off; hosts enable the ones they have.
  mg.notify.enable = true;

  time.timeZone = "Europe/Berlin";

  users.users.mg = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  # create /bin/bash symlink to make common shebangs work
  systemd.tmpfiles.rules = [
    "L+ /bin/bash - - - - ${pkgs.bash}/bin/bash"
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    zlib
    openssl
    stdenv.cc.cc
  ];

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
    bubblewrap

    # notifications
    gotify-cli

    # backups
    restic
    fuse
    sops
  ];
}
