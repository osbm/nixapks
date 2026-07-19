{
  inputs,
  ...
}:
{
  # Overlay to extend lib with our custom functions
  libOverlay = _final: prev: {
    inherit ((prev.callPackage ./builders/gradle-dot-nix.nix { inherit inputs; })) buildGradleApk;
    inherit ((prev.callPackage ./builders/verify-apk-meta.nix { })) verifyApkMeta;
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
      # Required metadata for every in-tree APK. Missing fields are a hard
      # eval error, not a warning: warnings scroll past unread.
      requiredMeta = [
        "description"
        "homepage"
        "maintainers"
        "license"
        "sourceProvenance"
        "android"
      ];
      requiredAndroid = [
        "minSdk"
        "targetSdk"
        "applicationId"
        "abis"
      ];

      missingIn =
        set: prefix: attrs:
        map (a: "${prefix}${a}") (
          builtins.filter (a: !(set ? ${a}) || set.${a} == null || set.${a} == [ ]) attrs
        );

      checkPackage =
        name: pkg:
        let
          missing =
            missingIn pkg.meta "meta." requiredMeta
            ++ lib.optionals (pkg.meta ? android && pkg.meta.android != null) (
              missingIn pkg.meta.android "meta.android." requiredAndroid
            );
        in
        lib.throwIf (missing != [ ])
          "APK ${name} is missing required fields: ${lib.concatStringsSep ", " missing}"
          (
            lib.warnIf (pkg.buildInputs or [ ] != [ ] || pkg.propagatedBuildInputs or [ ] != [ ])
              "APK ${name} has (propagated)buildInputs which cause runtime dependencies. APKs should have none."
              pkg
          );
    in
    lib.mapAttrs (
      name: path: checkPackage name (pkgs'.callPackage path { inherit inputs; })
    ) packageFiles;
}
