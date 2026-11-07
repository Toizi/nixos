# Public entrypoint. Every hostname derives from mg.vps.domain (set by the
# private flake); ports 2001/2002 mirror the previous setup.
{ config, lib, ... }:

let
  d = config.mg.vps.domain;
  proxy = port: ''
    reverse_proxy 127.0.0.1:${toString port} {
      header_down Strict-Transport-Security max-age=31536000
    }
  '';
in
{
  options.mg.vps.domain = lib.mkOption {
    type = lib.types.str;
    description = "Base domain the services are published under.";
    example = "example.org";
  };

  config = {
    services.caddy = {
      enable = true;
      virtualHosts = {
        # gotify
        "${d}:2001".extraConfig = proxy 3001;
        # restic REST server
        "${d}:2002".extraConfig = proxy 3002;
        # authelia
        "auth.${d}".extraConfig = ''
          header Strict-Transport-Security max-age=31536000
          reverse_proxy 127.0.0.1:3009
        '';
        # open-webui, behind authelia
        "chat.${d}".extraConfig = ''
          header Strict-Transport-Security max-age=31536000
          forward_auth 127.0.0.1:3009 {
            uri /api/authz/forward-auth
            copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
          }
          reverse_proxy 127.0.0.1:3008
        '';
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 80 443 2001 2002 ];
      allowedUDPPorts = [ 443 ]; # HTTP/3
    };
  };
}
