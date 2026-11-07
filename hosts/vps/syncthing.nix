# Syncthing with the data stored directly on this host (previously the folder
# lived on the storage box behind an rclone mount). Devices and folders are
# managed in the web UI (127.0.0.1:8384); the existing config is migrated, see
# the migration notes.
{ ... }:

{
  users.users.databoi = {
    isSystemUser = true;
    group = "databoi";
    home = "/home/databoi";
    createHome = true;
  };
  users.groups.databoi = { };

  services.syncthing = {
    enable = true;
    openDefaultPorts = true; # NOTE: does not open the GUI port
    user = "databoi";
    group = "databoi";
    dataDir = "/home/databoi/data";
    configDir = "/home/databoi/.config/syncthing";
  };
}
