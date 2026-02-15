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

  # === Version-pinned overrides ===

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
