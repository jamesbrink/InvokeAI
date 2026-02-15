# numtide/devshell module — categorized command menu for `nix develop`
{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      isDarwin = pkgs.stdenv.isDarwin;
      isLinux = pkgs.stdenv.isLinux;
    in
    {
      devshells.default = {
        name = "invokeai";

        # ── Commands ────────────────────────────────────────────

        commands = [
          # — python —
          {
            name = "ruff";
            command = "ruff check . --fix && ruff format .";
            help = "Run ruff check + format with safe fixes";
            category = "python";
          }
          {
            name = "ruff-unsafe";
            command = "ruff check . --fix --unsafe-fixes && ruff format .";
            help = "Run ruff check + format with unsafe fixes";
            category = "python";
          }
          {
            name = "mypy";
            command = "mypy scripts/invokeai-web.py";
            help = "Run mypy type checking";
            category = "python";
          }
          {
            name = "test";
            command = "pytest ./tests";
            help = "Run the test suite";
            category = "python";
          }
          {
            name = "openapi";
            command = "python scripts/generate_openapi_schema.py";
            help = "Generate OpenAPI schema";
            category = "python";
          }

          # — frontend —
          {
            name = "frontend-install";
            command = "cd invokeai/frontend/web && pnpm install";
            help = "Install pnpm dependencies for the frontend";
            category = "frontend";
          }
          {
            name = "frontend-build";
            command = "cd invokeai/frontend/web && pnpm build";
            help = "Build the frontend for production";
            category = "frontend";
          }
          {
            name = "frontend-dev";
            command = "cd invokeai/frontend/web && pnpm dev";
            help = "Start frontend dev server on localhost:5173";
            category = "frontend";
          }
          {
            name = "frontend-lint";
            command = "cd invokeai/frontend/web && pnpm lint";
            help = "Run all frontend lint checks";
            category = "frontend";
          }
          {
            name = "frontend-typegen";
            command = "cd invokeai/frontend/web && python ../../../scripts/generate_openapi_schema.py | pnpm typegen";
            help = "Generate TypeScript types from OpenAPI schema";
            category = "frontend";
          }

          # — build —
          {
            name = "build";
            command = "nix build";
            help = "Build InvokeAI via Nix";
            category = "build";
          }
        ]
        ++ lib.optionals isLinux [
          {
            name = "build-docker";
            command = "nix build .#docker";
            help = "Build the Docker image via Nix";
            category = "build";
          }
        ]
        ++ [
          # — formatting —
          {
            name = "fmt";
            command = "nix fmt";
            help = "Format all files via treefmt";
            category = "formatting";
          }
          {
            name = "fmt-check";
            command = "nix fmt -- --fail-on-change";
            help = "Check formatting without modifying files";
            category = "formatting";
          }
        ];

        # ── Packages ───────────────────────────────────────────

        packages =
          with pkgs;
          [
            # Python
            python312
            uv

            # Frontend
            nodejs_22
            pnpm_10

            # Build tools
            git
            cmake
            pkg-config
            ninja
            curl
          ]
          ++ lib.optionals isDarwin [
            libiconv
          ]
          ++ lib.optionals isLinux [
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            libGL
            glib
            stdenv.cc.cc.lib
          ];

        # ── Environment variables ──────────────────────────────

        env = lib.optionals isLinux [
          {
            name = "CUDA_HOME";
            value = "${pkgs.cudaPackages.cudatoolkit}";
          }
        ];

        # ── Startup hook ──────────────────────────────────────

        devshell.startup.setup.text = ''
          ${lib.optionalString isLinux ''
            export LD_LIBRARY_PATH="${
              lib.makeLibraryPath (
                with pkgs;
                [
                  stdenv.cc.cc.lib
                  libGL
                  glib
                  cudaPackages.cudatoolkit
                  cudaPackages.cudnn
                ]
              )
            }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
          ''}

          if [ ! -d "venv" ]; then
            echo "Creating Python virtual environment..."
            python3 -m venv venv
          fi
          source venv/bin/activate

          echo ""
          echo "InvokeAI development environment loaded."
          echo "Run 'pip install -e \".[dev,test,xformers]\"' to install Python deps."
          echo "Run 'menu' to see available commands."
        '';
      };
    };
}
