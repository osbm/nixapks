{ pkgs, ... }:

let
  buildToolsVersion = "34.0.0";
  platformVersion = "35";
  androidComposition = pkgs.androidenv.composeAndroidPackages {
    buildToolsVersions = [ buildToolsVersion ];
    platformToolsVersion = "35.0.2";
    platformVersions = [ platformVersion ];
    emulatorVersion = "35.2.5";
    includeEmulator = true;
    includeSystemImages = true;
    systemImageTypes = [ "google_apis"];
    abiVersions = [ "armeabi-v7a" "arm64-v8a" "x86_64" ];
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
  gradle = pkgs.gradle_8;
in

pkgs.stdenv.mkDerivation rec {
  name = "mihon-${version}.apk";
  version = "0.18.0";

  src = pkgs.fetchFromGitHub {
    owner = "mihonapp";
    repo = "mihon";
    tag = "v${version}";
    hash = "sha256-ZAjQu4GvxjqBmfPG4q38pA/26NXsRnZC6t7E+tg+UTc=";
  };
}
