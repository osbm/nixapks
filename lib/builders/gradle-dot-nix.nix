{
  pkgs,
  inputs,
  lib,
  ...
}:
{
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
      verificationMetadata,
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
      android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} androidSdkPackages;

      # Extract the build-tools version from androidSdkPackages
      # We'll use the first build-tools package found

      gradle-init-script =
        (import inputs.gradle-dot-nix {
          inherit pkgs;
          gradle-verification-metadata-file = verificationMetadata;
          public-maven-repos = mavenRepos;
        }).gradle-init;
    in
    pkgs.stdenv.mkDerivation {
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
        gradle ${gradleTask} --info -I ${gradle-init-script} \
          --offline --no-daemon --full-stacktrace \
          ${lib.concatStringsSep " " gradleFlags}
      '';

      installPhase = ''
        cp ${apkPath} $out
      '';

      meta = meta // {
        sourceProvenance = [
          pkgs.lib.sourceTypes.binaryByteCode
          pkgs.lib.sourceTypes.fromSource
        ];
      };
    };
}
