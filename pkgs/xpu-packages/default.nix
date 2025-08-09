{
  lib,
  callPackage,
  newScope,
}:

{
  packageMetadata,
}:

let
  fixedPoint = final: { inherit callPackage lib packageMetadata; };
  composed = lib.composeManyExtensions [
    # Hooks
    (import ./hooks.nix)
    # Base package set.
    (import ./components.nix)
    # Overrides (adding dependencies, etc.)
    (import ./overrides.nix)
    # Packages that are joins of other packages.
    (callPackage ./joins.nix { })
  ];
in
lib.makeScope newScope (lib.extends composed fixedPoint)
