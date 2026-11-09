# LiftLog backup receiver + read-only MCP server (services in the liftlog-mcp flake):
#   https://<mg.vps.domain>:2003/backup  -> receiver (the LiftLog app's remote backup, X-API-Key)
#   https://<mg.vps.domain>/mcp          -> MCP server for the Claude custom connector (X-API-Key)
# Nothing is enabled until the private flake supplies both environment files:
#   receiverEnvironmentFile: RECEIVER_API_KEY=...
#   mcpEnvironmentFile:      MCP_API_KEY=...
# Port 2003 is opened below; no extra DNS record is needed.
{ config, lib, ... }:

let
  cfg = config.mg.vps.liftlog;
  d = config.mg.vps.domain;
  ll = config.services.liftlog;
  enabled = cfg.receiverEnvironmentFile != null && cfg.mcpEnvironmentFile != null;
in
{
  options.mg.vps.liftlog = {
    receiverEnvironmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file with RECEIVER_API_KEY for the backup receiver.";
    };
    mcpEnvironmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Environment file with MCP_API_KEY for the MCP server.";
    };
  };

  config = lib.mkIf enabled {
    services.liftlog = {
      receiverEnvironmentFile = cfg.receiverEnvironmentFile;
      mcpEnvironmentFile = cfg.mcpEnvironmentFile;
    };

    networking.firewall.allowedTCPPorts = [ 2003 ];

    services.caddy.virtualHosts."${d}:2003".extraConfig = ''
      header Strict-Transport-Security max-age=31536000

      handle /backup {
        request_body {
          max_size 256MB
        }
        reverse_proxy 127.0.0.1:${toString ll.receiverPort}
      }
      handle {
        respond 404
      }
    '';

    # Claude's connector backend only dials port 443, so /mcp lives on the bare domain.
    services.caddy.virtualHosts."${d}".extraConfig = ''
      header Strict-Transport-Security max-age=31536000

      handle /mcp {
        reverse_proxy 127.0.0.1:${toString ll.mcpPort}
      }

      handle {
        respond 404
      }
    '';
  };
}
