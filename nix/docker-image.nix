# OCI/Docker image for InvokeAI
# Build with: nix build .#docker
# Load with:  ./result | docker load
# Run:        docker run -p 9090:9090 -v ./data:/data invokeai
{
  pkgs,
  lib,
  invokeai,
}:

pkgs.dockerTools.streamLayeredImage {
  name = "invokeai";
  tag = "latest";

  contents = pkgs.buildEnv {
    name = "invokeai-env";
    paths = with pkgs; [
      invokeai
      bashInteractive
      coreutils
      cacert
      git
    ];
    pathsToLink = [
      "/bin"
      "/lib"
      "/share"
    ];
  };

  extraCommands = ''
    mkdir -p usr/bin
    ln -s /bin/env usr/bin/env
    mkdir -p tmp
    chmod 1777 tmp
  '';

  config = {
    Entrypoint = [
      "${invokeai}/bin/invokeai-web"
    ];
    Cmd = [
      "--host"
      "0.0.0.0"
      "--port"
      "9090"
    ];
    WorkingDir = "/data";
    Volumes = {
      "/data" = { };
    };
    ExposedPorts = {
      "9090/tcp" = { };
    };
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      "INVOKEAI_ROOT=/data"
      "NVIDIA_VISIBLE_DEVICES=all"
      "NVIDIA_DRIVER_CAPABILITIES=compute,utility"
      "LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/usr/lib64:/usr/local/nvidia/lib64"
    ];
  };
}
