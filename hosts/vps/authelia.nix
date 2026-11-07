# Authelia (forward auth for Caddy). The full configuration (access control,
# users database path, session/storage secrets, SMTP, ...) is the existing
# configuration.yml, kept in the instance's state directory:
#   /var/lib/authelia-main/config/configuration.yml
# It is not managed here because it embeds secrets. Paths inside it must point
# below /var/lib/authelia-main (the container used /config and /data).
{ ... }:

{
  services.authelia.instances.main = {
    enable = true;
    secrets.manual = true;
    settingsFiles = [ "/var/lib/authelia-main/config/configuration.yml" ];
    # Environment overrides config files: pin the listener to what Caddy expects.
    environmentVariables.AUTHELIA_SERVER_ADDRESS = "tcp://127.0.0.1:3009/";
  };
}
