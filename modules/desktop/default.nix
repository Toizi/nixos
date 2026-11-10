# Graphical workstation: Hyprland session, GUI apps, audio, desktop notifications.
{ lib, pkgs, ... }:

{
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "spotify"
  ];

  programs.hyprland.enable = true;
  programs.hyprlock.enable = true;

  # hypridle's unit PATH lacks bash; ~/.my_scripts/quirk_control_dpms needs bash + flock.
  systemd.user.services.hypridle.path = with pkgs; [ bash util-linux ];

  programs.firefox.enable = true;
  programs.thunderbird.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  mg.notify = {
    desktop.enable = true;
    defaultChannels = [ "desktop" ];
  };

  environment.systemPackages = with pkgs; [
    ungoogled-chromium
    pavucontrol
    libnotify
    dunst
  ];
}
