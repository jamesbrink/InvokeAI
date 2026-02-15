# Main InvokeAI package derivation
{
  lib,
  stdenv,
  makeWrapper,
  python3,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  fetchPnpmDeps,
  git,
  cacert,
}:

let
  version = "6.11.1.post1";

  pythonEnv = python3.withPackages (
    ps:
    with ps;
    [
      # Core generation dependencies
      accelerate
      compel
      diffusers
      gguf
      numpy
      onnx
      onnxruntime
      opencv4
      safetensors
      sentencepiece
      spandrel
      torch
      torchsde
      torchvision
      transformers

      # Core application dependencies
      fastapi
      fastapi-events
      huggingface-hub
      pydantic
      pydantic-settings
      python-socketio
      uvicorn

      # Auxiliary dependencies
      blake3
      deprecated
      dnspython
      dynamicprompts
      einops
      picklescan
      pillow
      prompt-toolkit
      pypatchmatch
      python-multipart
      requests
      semver
      pywavelets

      # Build/runtime
      setuptools
    ]
    ++ lib.optionals stdenv.isLinux [
      bitsandbytes
    ]
  );

  # Frontend build — pure derivation using pnpm
  frontend = stdenv.mkDerivation {
    pname = "invokeai-frontend";
    inherit version;

    src = lib.cleanSourceWith {
      src = ./../invokeai/frontend/web;
      filter =
        path: type:
        let
          baseName = baseNameOf path;
        in
        !(baseName == "node_modules" || baseName == ".next" || baseName == "dist" || baseName == ".turbo");
    };

    nativeBuildInputs = [
      nodejs_22
      pnpm_10
      pnpmConfigHook
      cacert
    ];

    pnpmDeps = fetchPnpmDeps {
      pname = "invokeai-frontend";
      inherit version;
      src = lib.cleanSourceWith {
        src = ./../invokeai/frontend/web;
        filter =
          path: type:
          let
            baseName = baseNameOf path;
          in
          !(baseName == "node_modules" || baseName == ".next" || baseName == "dist" || baseName == ".turbo");
      };
      fetcherVersion = 3;
      hash = "sha256-Fe6iL0KuwkztBEdd7JwWgyMrCCEGqAvvey8HIhCtgpM=";
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  sourceFilter =
    path: type:
    let
      baseName = baseNameOf path;
    in
    !(
      baseName == ".git"
      || baseName == "venv"
      || baseName == ".venv"
      || baseName == "node_modules"
      || baseName == "__pycache__"
      || baseName == ".direnv"
      || baseName == "result"
      || baseName == ".mypy_cache"
      || baseName == ".ruff_cache"
      || lib.hasSuffix ".pyc" baseName
    );
in
stdenv.mkDerivation {
  pname = "invokeai";
  inherit version;

  src = lib.cleanSourceWith {
    src = ./..;
    filter = sourceFilter;
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Copy source tree into the store
    mkdir -p $out/lib/invokeai
    cp -r . $out/lib/invokeai/

    # Overlay the pre-built frontend
    mkdir -p $out/lib/invokeai/invokeai/frontend/web/dist
    cp -r ${frontend}/* $out/lib/invokeai/invokeai/frontend/web/dist/

    mkdir -p $out/bin

    # Main entry point wrapper
    makeWrapper ${pythonEnv}/bin/python $out/bin/invokeai-web \
      --add-flags "-m" \
      --add-flags "invokeai.app.run_app" \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --set PYTHONPATH "$out/lib/invokeai" \
      --set-default INVOKEAI_ROOT "$HOME/invokeai"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A full-featured AI-assisted image generation environment designed for creatives and enthusiasts";
    homepage = "https://invoke-ai.github.io/InvokeAI/";
    license = licenses.asl20;
    platforms = platforms.unix;
    mainProgram = "invokeai-web";
  };
}
