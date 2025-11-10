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
      lib.warnIf
        (!(pkg.meta ? description) || pkg.meta.description == null)
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

        lib.warnIf
        (!(pkg.meta ? sourceProvance) || pkg.meta.sourceProvance == null)
        "APK ${name} is missing a meta.sourceProvance field."

        lib.warnIf
        (!(pkg.meta ? android) || pkg.meta.android == null)
        "APK ${name} is missing a meta.android field."

        lib.warnIf
        (pkg.meta ? android && (!(pkg.meta.android ? minSdk) || pkg.meta.android.minSdk == null))
        "APK ${name} is missing meta.android.minSdk field."

        lib.warnIf
        (pkg.meta ? android && (!(pkg.meta.android ? targetSdk) || pkg.meta.android.targetSdk == null))
        "APK ${name} is missing meta.android.targetSdk field."

        lib.warnIf
        (
          pkg.meta ? android
          && (!(pkg.meta.android ? applicationId) || pkg.meta.android.applicationId == null)
        )
        "APK ${name} is missing meta.android.applicationId field."

        lib.warnIf
        (
          pkg.meta ? android
          && (!(pkg.meta.android ? abis) || pkg.meta.android.abis == null || pkg.meta.android.abis == [ ])
        )
        "APK ${name} is missing or has empty meta.android.abis field."

        lib.warnIf
        (pkg ? buildInputs && pkg.buildInputs != [ ])
        "APK ${name} has buildInputs which may cause runtime dependencies. APKs should have no runtime dependencies."

        lib.warnIf
        (pkg ? propagatedBuildInputs && pkg.propagatedBuildInputs != [ ])
        "APK ${name} has propagatedBuildInputs which will cause runtime dependencies. APKs should have no runtime dependencies."

        pkg
    ) packageFiles;
}
