# Tailscale Android APK
# Latest releases: https://github.com/tailscale/tailscale-android/releases
# To get the hash: nix-prefetch-url --unpack https://github.com/tailscale/tailscale-android/archive/v{VERSION}.tar.gz
{
  stdenv,
  fetchFromGitHub,
  gradle_8,
  jdk21,
  git,
  androidenv,
  ...
}:
let
  gradle = gradle_8;
  buildToolsVersion = "35.0.1";
  platformVersion = "35";
  androidComposition = androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion ];
    platformToolsVersion = "35.0.2";
    platformVersions = [ platformVersion ];
    includeSystemImages = true;
    systemImageTypes = [ "google_apis"];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" "x86_64" ];
    extraLicenses = [
      "android-sdk-license"
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
    ];
  };
in
stdenv.mkDerivation (finalAttrs: rec {
  name = "tailscale-${version}.apk";
  # TODO: Update version to latest release from https://github.com/tailscale/tailscale-android/releases
  version = "1.78.1";

  src = fetchFromGitHub {
    owner = "tailscale";
    repo = "tailscale-android";
    rev = "v${version}";
    # TODO: Update hash - run `nix-prefetch-url --unpack https://github.com/tailscale/tailscale-android/archive/v${version}.tar.gz`
    hash = "sha256-0000000000000000000000000000000000000000000=";
    leaveDotGit = true;
  };

  nativeBuildInputs = [
    gradle
    git
    androidComposition.androidsdk
  ];

  buildInputs = [
    git
    jdk21
  ];
  
  ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";
  ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";
  GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2";
  JDK_HOME = "${jdk21.home}";

  gradleFlags = [ 
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=${ANDROID_HOME}/build-tools/${buildToolsVersion}/aapt2" 
    "-Dfile.encoding=utf-8" 
    "-Pandroid.buildType=release" 
    "-Pandroid.testBuildType=release"
  ];
  
  preBuild = ''
    export TMPDIR=$(mktemp -d)
    export GRADLE_USER_HOME=$TMPDIR/.gradle
    # Ensure AAPT2 has a writable directory
    mkdir -p $TMPDIR/aapt2
    export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
  '';

  gradleUpdateTask = "assembleRelease";
  gradleBuildTask = "assembleRelease";

  mitmCache = gradle.fetchDeps {
    pkg = finalAttrs;
    data = ./deps.json;
  };

  installPhase = ''
    # TODO: Verify APK output path - might be app-universal-release-unsigned.apk or app-release.apk
    cp app/build/outputs/apk/release/app-release.apk $out
  '';
})