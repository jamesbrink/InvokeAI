{
  description = "InvokeAI - A full-featured AI-assisted image generation environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
        ./nix/devshell.nix
      ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Non-per-system outputs: overlay and service modules
      flake = {
        overlays.default = import ./nix/overlay.nix;
        nixosModules.default = import ./nix/modules/nixos.nix;
        darwinModules.default = import ./nix/modules/darwin.nix;
      };

      perSystem =
        { lib, system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
            };
          };

          isDarwin = pkgs.stdenv.isDarwin;
          isLinux = pkgs.stdenv.isLinux;

          python3 = pkgs.python312.override {
            packageOverrides = import ./nix/python-packages.nix {
              inherit pkgs lib;
            };
          };

          invokeai = pkgs.callPackage ./nix/invokeai.nix {
            inherit python3;
          };

          docker-image = pkgs.callPackage ./nix/docker-image.nix {
            inherit invokeai;
          };
        in
        {
          # Override the default pkgs so all perSystem modules (including devshell)
          # get nixpkgs with allowUnfree = true (required for CUDA on Linux).
          _module.args.pkgs = pkgs;

          # treefmt — provides `nix fmt` and `checks.treefmt`
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              nixfmt.enable = true;
              ruff = {
                enable = true;
                format = true;
              };
              prettier = {
                enable = true;
                includes = [ "invokeai/frontend/web/**/*.{ts,tsx,js,jsx,css,json}" ];
                excludes = [
                  "invokeai/frontend/web/node_modules/**"
                  "invokeai/frontend/web/dist/**"
                ];
              };
            };
          };

          # nix build / nix build .#default
          packages = {
            default = invokeai;
            invokeai = invokeai;
          }
          // lib.optionalAttrs isLinux {
            docker = docker-image;
          };

          # nix run / nix run .#default
          apps = {
            default = {
              type = "app";
              program = "${invokeai}/bin/invokeai-web";
              meta.description = "Start the InvokeAI web interface";
            };
          };

          # nix develop — provided by ./nix/devshell.nix
        };
    };
}
