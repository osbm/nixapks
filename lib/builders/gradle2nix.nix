{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # APK builder backed by gradle2nix v2 (github:tadfisher/gradle2nix).
  #
  # Locking method: run the gradle2nix CLI against the app source to produce
  # a per-app gradle.lock (JSON), commit it next to package.nix. The builder
  # constructs an offline Maven repo from the lock and drives Gradle through
  # gradle2nix's setup hook.
  #
  # One of several deliberately-coexisting methods (see also
  # buildGradleApkGradleDotNix and buildGradleApkCentralizedLock) kept alive
  # to compare maintainability, update ergonomics, and breakage rates.
  buildGradleApkGradle2Nix =
    {
      pname,
      version,
      src,
      androidSdkPackages,
      gradleTask,
      gradleFlags ? [ ],
      lockFile,
      apkPath,
      jdk ? pkgs.jdk21,
      extraNativeBuildInputs ? [ ],
      meta ? { },
    }:
    let
      system = pkgs.stdenv.hostPlatform.system;
      android-sdk = inputs.android-nixpkgs.sdk.${system} androidSdkPackages;
      inherit ((import ./verify-apk-meta.nix { inherit pkgs lib; })) verifyApkMeta;

      apk = inputs.gradle2nix.builders.${system}.buildGradlePackage {
        # repo convention: derivation name is <pname>-<version>.apk
        name = "${pname}-${version}.apk";
        inherit
          pname
          version
          src
          lockFile
          ;
        buildJdk = jdk;

        ANDROID_HOME = "${android-sdk}/share/android-sdk";
        ANDROID_SDK_ROOT = "${android-sdk}/share/android-sdk";

        gradleBuildFlags = [
          gradleTask
          "-Dorg.gradle.project.android.aapt2FromMavenOverride=${android-sdk}/share/android-sdk/build-tools/36.0.0/aapt2"
          "-Dfile.encoding=utf-8"
        ]
        ++ gradleFlags;

        nativeBuildInputs = [
          android-sdk
          jdk
        ]
        ++ extraNativeBuildInputs;

        installPhase = ''
          runHook preInstall
          cp ${apkPath} $out
          runHook postInstall
        '';

        meta = meta // {
          sourceProvenance = [
            lib.sourceTypes.binaryBytecode
            lib.sourceTypes.fromSource
          ];
        };
      };
    in
    apk
    // lib.optionalAttrs (meta ? android) {
      tests.meta = verifyApkMeta {
        apk = apk // {
          name = "${pname}-${version}.apk";
        };
        sdk = android-sdk;
        inherit version;
        inherit (meta) android;
      };
    };
}
