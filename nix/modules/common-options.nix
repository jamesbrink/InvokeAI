# Shared option declarations for InvokeAI service modules.
# Imported by both the NixOS and nix-darwin modules.
{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.services.invokeai = {
    enable = mkEnableOption "InvokeAI web UI service";

    package = mkOption {
      type = types.package;
      description = "The InvokeAI package to use.";
    };

    port = mkOption {
      type = types.port;
      default = 9090;
      description = "Port for the web UI to listen on.";
    };

    host = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "Bind address for the web UI.";
    };

    dataDir = mkOption {
      type = types.str;
      description = ''
        Directory for writable data (models, outputs, database).
        Default is platform-specific: /var/lib/invokeai on NixOS,
        ~/Library/Application Support/InvokeAI on Darwin.
        The INVOKEAI_ROOT environment variable always takes precedence.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "invokeai";
      description = ''
        User to run the service as.
        On NixOS, a system user is created automatically.
        On Darwin, this should be an existing login user.
      '';
    };

    group = mkOption {
      type = types.str;
      default = "invokeai";
      description = "Group for the service. Only used on NixOS.";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to open the firewall for the web UI port. Only effective on NixOS.";
    };

    extraArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional command-line arguments passed to invokeai-web.";
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Path to an environment file with secrets (e.g. HF_TOKEN).
        Loaded before the service starts.
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Additional environment variables for the service.";
    };
  };
}
