# Open WebUI behind Caddy, authenticated through Authelia (forward auth).
# Runtime settings (secret key, trusted-header auth, backend URLs, ...) come from
# mg.vps.openWebuiEnvironmentFile, supplied by the private flake.
{ config, lib, ... }:

{
  options.mg.vps.openWebuiEnvironmentFile = lib.mkOption {
    type = lib.types.nullOr lib.types.path;
    default = null;
    description = "Environment file for Open WebUI (secrets live here).";
  };

  config.services.open-webui = {
    enable = true;
    host = "127.0.0.1";
    port = 3008;
    environmentFile = config.mg.vps.openWebuiEnvironmentFile;
  };
}
