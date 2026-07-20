{
  pkgs,
  inputs,
  lib,
  ...
}:
rec {
  # Core gradle-dot-nix-based builder. Use the named variants below so each
  # locking method is identifiable in package files (the repo deliberately
  # keeps multiple methods alive to compare them).
  buildGradleApk =
    {
      pname,
      version,
      src,
      # Android SDK configuration
      androidSdkPackages,
      # Gradle configuration
      gradleTask,
      gradleFlags ? [ ],
      # Per-app gradle verification metadata file. When null, the metadata is
      # generated from the central lockfile (lib/maven-lock.json) instead —
      # apps then need no per-app hash file at all.
      verificationMetadata ? null,
      mavenLock ? ../maven-lock.json,
      # APK output configuration
      apkPath,
      # Optional parameters
      jdk ? pkgs.jdk21,
      gradle ? pkgs.gradle_8,
      mavenRepos ? ''
        [
            "https://dl.google.com/dl/android/maven2",
            "https://repo.maven.apache.org/maven2",
            "https://plugins.gradle.org/m2",
            "https://maven.google.com",
            "https://www.jitpack.io"
        ]
      '',
      preBuild ? "",
      extraNativeBuildInputs ? [ ],
      extraGradleOpts ? "",
      meta ? { },
    }:
    let
      inherit ((import ./verify-apk-meta.nix { inherit pkgs lib; })) verifyApkMeta;

      android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} androidSdkPackages;

      # Extract the build-tools version from androidSdkPackages
      # We'll use the first build-tools package found

      # Render the central lockfile into the verification-metadata.xml shape
      # that gradle-dot-nix's parser consumes. The lock is a superset of all
      # apps' dependencies; gradle's own resolution picks what it needs.
      componentXml =
        coordinate: files:
        let
          parts = lib.splitString ":" coordinate;
        in
        ''
          <component group="${builtins.elemAt parts 0}" name="${builtins.elemAt parts 1}" version="${builtins.elemAt parts 2}">
          ${lib.concatStrings (
            lib.mapAttrsToList (fname: hash: ''
              <artifact name="${fname}">
                 <sha256 value="${hash}"/>
              </artifact>
            '') files
          )}
          </component>
        '';

      lockMetadataFile = pkgs.writeText "verification-metadata.xml" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <verification-metadata xmlns="https://schema.gradle.org/dependency-verification" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://schema.gradle.org/dependency-verification https://schema.gradle.org/dependency-verification/dependency-verification-1.3.xsd">
           <configuration>
              <verify-metadata>true</verify-metadata>
              <verify-signatures>false</verify-signatures>
           </configuration>
           <components>
        ${lib.concatStrings (
          lib.mapAttrsToList componentXml (builtins.fromJSON (builtins.readFile mavenLock))
        )}
           </components>
        </verification-metadata>
      '';

      gradle-init-script =
        (import inputs.gradle-dot-nix {
          inherit pkgs;
          gradle-verification-metadata-file =
            if verificationMetadata != null then verificationMetadata else lockMetadataFile;
          public-maven-repos = mavenRepos;
        }).gradle-init;
    in
    pkgs.stdenv.mkDerivation (finalAttrs: {
      name = "${pname}-${version}.apk";
      inherit version src;

      JDK_HOME = "${jdk.home}";
      ANDROID_HOME = "${android-sdk}/share/android-sdk";
      ANDROID_NDK_ROOT = "\${ANDROID_HOME}/ndk-bundle";

      nativeBuildInputs = [
        android-sdk
        gradle
        jdk
      ]
      ++ extraNativeBuildInputs;

      preBuild = ''
        export TMPDIR=$(mktemp -d)
        export GRADLE_USER_HOME=$TMPDIR/.gradle
        mkdir -p $TMPDIR/aapt2
        export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
        ${extraGradleOpts}
        ${preBuild}
      '';

      buildPhase = ''
        runHook preBuild

        gradle ${gradleTask} --info -I ${gradle-init-script} \
          --offline --no-daemon --full-stacktrace \
          ${lib.concatStringsSep " " gradleFlags}

        runHook postBuild
      '';

      installPhase = ''
        runHook preInstall
        cp ${apkPath} $out
        runHook postInstall
      '';

      passthru = lib.optionalAttrs (meta ? android) {
        tests.meta = verifyApkMeta {
          apk = finalAttrs.finalPackage;
          sdk = android-sdk;
          inherit version;
          inherit (meta) android;
        };
      };

      meta = meta // {
        sourceProvenance = [
          lib.sourceTypes.binaryBytecode
          lib.sourceTypes.fromSource
        ];
      };
    });

  # gradle-dot-nix with a per-app verification-metadata.xml
  buildGradleApkGradleDotNix =
    args:
    lib.throwIfNot (args ? verificationMetadata)
      "buildGradleApkGradleDotNix requires verificationMetadata; use buildGradleApkCentralizedLock for the central lockfile"
      (buildGradleApk args);

  # gradle-dot-nix fed from the central lib/maven-lock.json
  buildGradleApkCentralizedLock =
    args:
    lib.throwIfNot (!(args ? verificationMetadata))
      "buildGradleApkCentralizedLock uses lib/maven-lock.json; do not pass verificationMetadata (use buildGradleApkGradleDotNix for per-app metadata)"
      (buildGradleApk args);
}
