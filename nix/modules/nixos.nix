# NixOS module for InvokeAI
#
# Usage:
#   imports = [ invokeai.nixosModules.default ];
#   services.invokeai = {
#     enable = true;
#     openFirewall = true;
#     environmentFile = "/run/secrets/invokeai.env";
#   };
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.invokeai;
  inherit (lib) mkDefault mkIf mkMerge;

  # Only use StateDirectory when dataDir is the default /var/lib/invokeai
  useStateDirectory = cfg.dataDir == "/var/lib/invokeai";
in
{
  imports = [ ./common-options.nix ];

  config = mkIf cfg.enable (mkMerge [
    {
      services.invokeai = {
        package = mkDefault pkgs.invokeai;
        dataDir = mkDefault "/var/lib/invokeai";
      };

      systemd.services.invokeai = {
        description = "InvokeAI - AI Image Generation";
        after = [ "network.target" ] ++ cfg.requiresMounts;
        requires = cfg.requiresMounts;
        wantedBy = [ "multi-user.target" ];

        environment = {
          INVOKEAI_ROOT = cfg.dataDir;
          INVOKEAI_HOST = cfg.host;
          INVOKEAI_PORT = toString cfg.port;
        }
        // cfg.environment;

        serviceConfig = {
          Type = "exec";
          ExecStart = lib.concatStringsSep " " (
            [
              "${cfg.package}/bin/invokeai-web"
            ]
            ++ cfg.extraArgs
          );
          User = cfg.user;
          Group = cfg.group;

          Restart = "on-failure";
          RestartSec = 5;

          # Hardening
          ProtectSystem = "strict";
          ReadWritePaths = [ cfg.dataDir ];
          ProtectHome = if cfg.createUser then true else "read-only";
          PrivateTmp = true;
          NoNewPrivileges = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;

          # GPU access needed for inference
          PrivateDevices = false;
          SupplementaryGroups = [
            "video"
            "render"
          ];
        }
        // lib.optionalAttrs useStateDirectory {
          StateDirectory = "invokeai";
          StateDirectoryMode = "0750";
        }
        // lib.optionalAttrs (cfg.environmentFile != null) {
          EnvironmentFile = cfg.environmentFile;
        };
      };
    }

    (mkIf cfg.createUser {
      users.users.${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        home = cfg.dataDir;
        description = "InvokeAI service user";
      };
      users.groups.${cfg.group} = { };
    })

    (mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [ cfg.port ];
    })
  ]);
}
