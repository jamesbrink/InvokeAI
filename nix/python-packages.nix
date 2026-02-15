# Python package overlay for InvokeAI
# Adds missing packages, pins versions, and provides platform-specific PyTorch
{ pkgs, lib }:

self: super:
{
  # === CUDA-enabled PyTorch on Linux ===
  # Use pre-built wheels (torch-bin) that include CUDA runtime libraries.
  # This aliases torch -> torch-bin so all transitive dependencies also get CUDA.
}
// lib.optionalAttrs pkgs.stdenv.isLinux {
  torch = super.torch-bin.overridePythonAttrs (old: {
    passthru = (old.passthru or { }) // {
      cudaSupport = true;
      cudaPackages = pkgs.cudaPackages;
      rocmSupport = false;
    };
  });
  torchvision = super.torchvision-bin;
}
// {
  # === nixpkgs package fixes ===

  # accelerate tests fail when torch-bin's inductor can't find a C compiler in the sandbox
  accelerate = super.accelerate.overridePythonAttrs (old: {
    doCheck = false;
  });

  # bitsandbytes needs ninja at build time for CUDA kernels
  bitsandbytes = super.bitsandbytes.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.ninja ];
  });

  # torchao inductor tests fail without a C compiler in the Nix sandbox
  torchao = super.torchao.overridePythonAttrs (old: {
    doCheck = false;
  });

  # timm inductor test fails without a C compiler in the Nix sandbox
  timm = super.timm.overridePythonAttrs (old: {
    doCheck = false;
  });

  # rapidfuzz C extension fails on macOS (libatomic not available with clang)
  rapidfuzz = super.rapidfuzz.overridePythonAttrs (
    old:
    lib.optionalAttrs pkgs.stdenv.isDarwin {
      env = (old.env or { }) // {
        RAPIDFUZZ_BUILD_EXTENSION = "0";
      };
      doCheck = false;
    }
  );

  # === Missing packages (not in nixpkgs) ===

  compel = self.buildPythonPackage rec {
    pname = "compel";
    version = "2.1.1";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-miAYGXIxk6Cz71wJChUOZLTvXgFxUmLc5yPr0ysi33w=";
    };

    build-system = [ self.setuptools ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    dependencies = with self; [
      diffusers
      pyparsing
      torch
      transformers
    ];

    doCheck = false;
    pythonImportsCheck = [ "compel" ];
  };

  spandrel = self.buildPythonPackage rec {
    pname = "spandrel";
    version = "0.4.1";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-ZG2YFqlC5Z1WqrLckENTlS5X3uSyyz9Z9+pNwPsRofI=";
    };

    build-system = [ self.setuptools ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    dependencies = with self; [
      torch
      torchvision
      safetensors
      einops
    ];

    doCheck = false;
    pythonImportsCheck = [ "spandrel" ];
  };

  torchsde = self.buildPythonPackage rec {
    pname = "torchsde";
    version = "0.2.6";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-gdB001BPnRkPFpT7UmOVr75GCO5DqIrbEmKmOeW0d4s=";
    };

    build-system = [ self.setuptools ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    dependencies = with self; [
      torch
      trampoline
      numpy
      scipy
    ];

    doCheck = false;
    pythonImportsCheck = [ "torchsde" ];
  };

  trampoline = self.buildPythonPackage rec {
    pname = "trampoline";
    version = "0.1.2";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/py3/t/trampoline/trampoline-0.1.2-py3-none-any.whl";
      hash = "sha256-NsyaT/mBGEPRd/wOB0DvvX2jnq3+blDJ4pN8vAbYmdk=";
    };

    doCheck = false;
  };

  dynamicprompts = self.buildPythonPackage rec {
    pname = "dynamicprompts";
    version = "0.31.0";
    format = "wheel";

    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/py3/d/dynamicprompts/dynamicprompts-${version}-py3-none-any.whl";
      hash = "sha256-oH84wpXsK3eQXOy6iw9Dm7GoSUK/todP9rVUSOLMlQ4=";
    };

    dependencies = with self; [
      pyparsing
      jinja2
    ];

    doCheck = false;
    pythonImportsCheck = [ "dynamicprompts" ];
  };

  picklescan = self.buildPythonPackage rec {
    pname = "picklescan";
    version = "0.0.23";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-UGnBcuypczbinA0etyjv223yLVB7Qk7+joCD6tfzQWw=";
    };

    build-system = [ self.setuptools ];

    doCheck = false;
    pythonImportsCheck = [ "picklescan" ];
  };

  gguf = self.buildPythonPackage rec {
    pname = "gguf";
    version = "0.16.3";
    pyproject = true;

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-7muCe/g8iZ/oJ2vsJ2xDpvaxyLgCfvvr+kyPqFKl09U=";
    };

    build-system = [ self.poetry-core ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    dependencies = with self; [
      numpy
      tqdm
      pyyaml
      sentencepiece
    ];

    doCheck = false;
    pythonImportsCheck = [ "gguf" ];
  };

  pypatchmatch = self.buildPythonPackage rec {
    pname = "pypatchmatch";
    version = "1.0.2";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "PyPatchMatch";
      inherit version;
      hash = "sha256-fgHjMs3/oIKgwP11LrdkQWfo9OUpe0ZPUBQY6ucHm0E=";
    };

    build-system = [ self.setuptools ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    # Relax pinned setuptools==67.1.0 build requirement
    postPatch = ''
      sed -i 's/setuptools == 67.1.0/setuptools/' pyproject.toml
    '';

    dependencies = with self; [
      numpy
      pillow
      tqdm
    ];

    doCheck = false;
  };

  fastapi-events = self.buildPythonPackage rec {
    pname = "fastapi-events";
    version = "0.11.1";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "fastapi-events";
      inherit version;
      hash = "sha256-u/pw9MJk69c+H8dLZTcXvwPyp+ns9oAIzUQXMEpPd50=";
    };

    build-system = [ self.setuptools ];
    nativeBuildInputs = [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;

    dependencies = with self; [
      fastapi
      starlette
    ];

    doCheck = false;
  };

  # mediapipe — pre-built wheels, platform-specific
  mediapipe =
    let
      version = "0.10.14";
      wheelData = {
        aarch64-darwin = {
          url = "https://files.pythonhosted.org/packages/2d/df/be410905b9757de4b00891dd34236d96e6db150b624f28cc27cd90c74564/mediapipe-${version}-cp312-cp312-macosx_11_0_universal2.whl";
          hash = "sha256-qiKYwYhnFs3mvXzparoVBdZ9Uu2rqFb2wuGrkF3lKw0=";
        };
        x86_64-darwin = {
          url = "https://files.pythonhosted.org/packages/2d/df/be410905b9757de4b00891dd34236d96e6db150b624f28cc27cd90c74564/mediapipe-${version}-cp312-cp312-macosx_11_0_universal2.whl";
          hash = "sha256-qiKYwYhnFs3mvXzparoVBdZ9Uu2rqFb2wuGrkF3lKw0=";
        };
        aarch64-linux = {
          url = "https://files.pythonhosted.org/packages/f4/da/dfed8db260b3fbe4e24ac17dda32c55787643a656d8d4e78c55bc847efa8/mediapipe-${version}-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl";
          hash = "sha256-PjDtLzn5JZJN5Yre7GqOYbpr62lZMl3A2KGqSHp0N3s=";
        };
        x86_64-linux = {
          url = "https://files.pythonhosted.org/packages/11/73/07c6dcbb322f86e2b8526e0073456dbdd2813d5351f772f882123c985fda/mediapipe-${version}-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
          hash = "sha256-mx5y11TNnhtLiNgOyerS8cvoQkt/iD072lM0G5gqn4s=";
        };
      };
      platData = wheelData.${pkgs.stdenv.hostPlatform.system};

      # The mediapipe wheel has RECORD entries without hashes (version.txt),
      # which causes the nixpkgs wheel repacker to fail. Pre-patch the wheel.
      # Fix wheel RECORD: add hash entries for files missing from or incomplete in RECORD.
      fixRecordScript = pkgs.writeText "fix-wheel-record.py" ''
        import zipfile, hashlib, base64, sys
        src_whl = sys.argv[1]
        out_whl = sys.argv[2]
        with zipfile.ZipFile(src_whl, "r") as zin:
            names = zin.namelist()
            record_name = [n for n in names if n.endswith("/RECORD")][0]
            record = zin.read(record_name).decode()
            # Parse existing RECORD entries
            recorded_files = set()
            new_lines = []
            for line in record.strip().split("\n"):
                parts = line.strip("\r").split(",")
                recorded_files.add(parts[0])
                if len(parts) >= 3 and parts[1] == "" and "RECORD" not in parts[0]:
                    fname = parts[0]
                    data = zin.read(fname)
                    digest = hashlib.sha256(data).digest()
                    b64 = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
                    new_lines.append(f"{fname},sha256={b64},{len(data)}")
                else:
                    new_lines.append(line.strip("\r"))
            # Add entries for files in the zip but missing from RECORD
            for name in names:
                if name not in recorded_files and not name.endswith("/") and name != record_name:
                    data = zin.read(name)
                    digest = hashlib.sha256(data).digest()
                    b64 = base64.urlsafe_b64encode(digest).rstrip(b"=").decode()
                    new_lines.append(f"{name},sha256={b64},{len(data)}")
            new_record = "\n".join(new_lines) + "\n"
            with zipfile.ZipFile(out_whl, "w") as zout:
                for item in zin.infolist():
                    if item.filename == record_name:
                        zout.writestr(item, new_record)
                    else:
                        zout.writestr(item, zin.read(item.filename))
      '';
      rawWheel = pkgs.fetchurl {
        inherit (platData) url hash;
        name = baseNameOf platData.url;
      };
      patchedWheel =
        pkgs.runCommand (baseNameOf platData.url)
          {
            nativeBuildInputs = [ pkgs.python312 ];
          }
          ''
            python3 ${fixRecordScript} ${rawWheel} $out
          '';
    in
    self.buildPythonPackage {
      pname = "mediapipe";
      inherit version;
      format = "wheel";

      src = patchedWheel;

      nativeBuildInputs = [ self.pythonRelaxDepsHook ];
      pythonRelaxDeps = true;
      pythonRemoveDeps = [ "opencv-contrib-python" ];

      dependencies = with self; [
        absl-py
        attrs
        flatbuffers
        matplotlib
        numpy
        opencv4
        protobuf
        sounddevice
      ];

      doCheck = false;
      pythonImportsCheck = [ "mediapipe" ];
    };

  # === Version-pinned overrides ===

  # InvokeAI requires fastapi 0.118.3 — 0.119.0+ breaks OpenAPI schema for AnyInvocation
  fastapi = super.fastapi.overridePythonAttrs (old: {
    version = "0.118.3";
    src = pkgs.fetchFromGitHub {
      owner = "fastapi";
      repo = "fastapi";
      rev = "0.118.3";
      hash = "sha256-MAuxbakxXfpT2+o5xGH5E38Nz44hel2WE+35UDpwlAs=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;
    doCheck = false;
  });

  # InvokeAI requires diffusers 0.36.0
  diffusers = super.diffusers.overridePythonAttrs (old: {
    version = "0.36.0";
    src = pkgs.fetchFromGitHub {
      owner = "huggingface";
      repo = "diffusers";
      rev = "v0.36.0";
      hash = "sha256-bDGiY1PR3JilEzkynUGE5IwDA+bgVQWW1jpGEfftI3U=";
    };
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ self.pythonRelaxDepsHook ];
    pythonRelaxDeps = true;
    dependencies = (old.dependencies or [ ]) ++ [ self.httpx ];
    doCheck = false;
  });
}
