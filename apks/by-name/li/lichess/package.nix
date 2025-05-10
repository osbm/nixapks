{
  lib,
  stdenv,
  pkgs
}:
let
  buildToolsVersion = "34.0.0";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion "30.0.3" ];
    platformVersions = [ "29" "30" "31" "32" "33" "34" "35" "28" ];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  #   toolsVersion = "26.1.1";
  #   platformToolsVersion = "33.0.3";
  #   # buildToolsVersions = [ buildToolsVersionForAapt2 ];
    includeEmulator = true;
    emulatorVersion = "34.1.19";
  #   platformVersions = [ "28" "29" "30" "31" ];
  #   includeSources = false;
  #   includeSystemImages = false;
  #   systemImageTypes = [ "google_apis_playstore" ];
  #   abiVersions = [ "armeabi-v7a" "arm64-v8a" ];
  #   cmakeVersions = [ "3.10.2" ];
    includeNDK = true;
    ndkVersions = [ "22.0.7026061" ];
  #   useGoogleAPIs = false;
    useGoogleTVAddOns = false;

    extraLicenses = [
      "android-googletv-license"
      "android-sdk-arm-dbt-license"
      "android-sdk-license"
      "android-sdk-preview-license"
      "google-gdk-license"
      "intel-android-extra-license"
      "intel-android-sysimage-license"
      "mips-android-sysimage-license"
   ];
  };
  androidSdk = androidComposition.androidsdk;
  # pubspecLock = pkgs.lib.importJSON ./pubspec.lock.json;
in
stdenv.mkDerivation rec {
  name = "lichess";
  version = "0.14.14";
  src = pkgs.fetchFromGitHub {
    owner = "lichess-org";
    repo = "mobile";
    tag = "v${version}";
    hash = "sha256-NqS3vyz9x2yILTuJxvnSz4F8ZpZ7NUf/+jVmxsqPWpk=";
  };


  nativeBuildInputs = [
    pkgs.flutter
  ];

  buildPhase = ''
    # export ANDROID_HOME=${pkgs.androidsdk}/libexec
    export ANDROID_SDK_ROOT=${androidSdk}/libexec/android-sdk
    # export ANDROID_NDK_HOME=${pkgs.androidndk}/libexec
    # export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH
    export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/34.0.0/aapt2"
    yarn install
    yarn android:build

    # The APK is built in the android/app/build/outputs/apk/debug directory


  '';

  installPhase = ''
    mkdir -p $out
    cp -r android/app/build/outputs/apk/debug/app-debug.apk $out/lichess.apk

  '';

  meta = with lib; {
    description = "Lichess mobile app";
  };

}
