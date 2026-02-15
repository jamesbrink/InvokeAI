# Package overlay for InvokeAI
#
# Usage in a NixOS or nix-darwin configuration:
#   nixpkgs.overlays = [ invokeai.overlays.default ];
#
# This adds pkgs.invokeai to nixpkgs.
#
# NOTE: On Linux, CUDA support requires allowUnfree in the consumer's nixpkgs config:
#   nixpkgs.config.allowUnfree = true;
final: prev:
let
  pythonOverlay = import ./python-packages.nix {
    pkgs = final;
    lib = final.lib;
  };

  python3 = final.python312.override {
    packageOverrides = pythonOverlay;
  };
in
{
  invokeai = final.callPackage ./invokeai.nix { inherit python3; };
}
