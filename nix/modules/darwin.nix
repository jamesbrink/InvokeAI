# nix-darwin module for InvokeAI
#
# Usage:
#   imports = [ invokeai.darwinModules.default ];
#   services.invokeai = {
#     enable = true;
#     user = "youruser";  # your macOS login username
#   };
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.invokeai;
  inherit (lib) mkDefault mkIf;

  envLines = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") cfg.environment
  );
in
{
  imports = [ ./common-options.nix ];

  config = mkIf cfg.enable {
    services.invokeai = {
      package = mkDefault pkgs.invokeai;
      dataDir = mkDefault "/Users/${cfg.user}/invokeai";
    };

    launchd.user.agents.invokeai = {
      script = ''
        set -euo pipefail

        export INVOKEAI_ROOT="${cfg.dataDir}"
        mkdir -p "${cfg.dataDir}"

        ${lib.optionalString (cfg.environmentFile != null) ''
          set -a
          source ${lib.escapeShellArg (toString cfg.environmentFile)}
          set +a
        ''}

        ${envLines}

        exec ${cfg.package}/bin/invokeai-web \
          --host ${cfg.host} \
          --port ${toString cfg.port} \
          ${lib.concatStringsSep " " cfg.extraArgs}
      '';

      serviceConfig = {
        Label = "ai.invoke.invokeai";
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${cfg.dataDir}/logs/stdout.log";
        StandardErrorPath = "${cfg.dataDir}/logs/stderr.log";
        ThrottleInterval = 5;
        AbandonProcessGroup = false;
        EnvironmentVariables = {
          PYTORCH_ENABLE_MPS_FALLBACK = "1";
        };
      };
    };
  };
}
