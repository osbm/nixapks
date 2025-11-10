{
  inputs,
  ...
}:
{
  # Overlay to extend lib with our custom functions
  libOverlay = _final: prev: {
    inherit ((prev.callPackage ./builders/gradle-dot-nix.nix { inherit inputs; })) buildGradleApk;
  };

  # Auto-discover packages by directory structure
  # Takes pkgs as parameter so it can be called with overlayed pkgs
  byNameOverlay =
    pkgs': baseDirectory:
    let
      namesForShard =
        shard: _:
        pkgs'.lib.mapAttrs (name: _: baseDirectory + "/${shard}/${name}/package.nix") (
          builtins.readDir (baseDirectory + "/${shard}")
        );
      packageFiles = pkgs'.lib.mergeAttrsList (
        pkgs'.lib.attrsets.mapAttrsToList namesForShard (builtins.readDir baseDirectory)
      );
    in
    pkgs'.lib.mapAttrs (_name: path: pkgs'.callPackage path { inherit inputs; }) packageFiles;
}
