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
      inherit (pkgs') lib;
      namesForShard =
        shard: _:
        lib.mapAttrs (name: _: baseDirectory + "/${shard}/${name}/package.nix") (
          builtins.readDir (baseDirectory + "/${shard}")
        );
      packageFiles = lib.mergeAttrsList (
        lib.attrsets.mapAttrsToList namesForShard (builtins.readDir baseDirectory)
      );
    in
    lib.mapAttrs (
      name: path:
      let
        pkg = pkgs'.callPackage path { inherit inputs; };
      in
      lib.warnIf (!(pkg.meta ? description) || pkg.meta.description == null)
        "APK ${name} is missing a meta.description field."

        lib.warnIf
        (!(pkg.meta ? homepage) || pkg.meta.homepage == null)
        "APK ${name} is missing a meta.homepage field."

        lib.warnIf
        (!(pkg.meta ? maintainers) || pkg.meta.maintainers == null)
        "APK ${name} is missing a meta.maintainers field."

        lib.warnIf
        (!(pkg.meta ? license) || pkg.meta.license == null)
        "APK ${name} is missing a meta.license field."

        pkg
    ) packageFiles;
}
