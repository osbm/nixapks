{
  pkgs,
  lib,
  ...
}:
lib.buildFlutterApk {
  pname = "obtainium";
  version = "1.7.4";

  src = pkgs.fetchFromGitHub {
    owner = "ImranR98";
    repo = "Obtainium";
    tag = "v1.7.4";
    hash = "sha256-rZWYn794wBQvtj3y1H4hJkvdyCRxkeM4L6YOTZorxOI=";
  };

  # upstream's .flutter submodule pins 3.47.9; pubspec.lock wants >=3.47.0
  flutter = pkgs.flutter347;

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = {
    android_package_installer = "sha256-t7x718urjE+GgU+jBUAkfTL9pjvMMg7RgK08cLDnchs=";
    android_package_manager = "sha256-AsuEMDhItxC/K9vCwX/Ob+gZGFmE54yvQgfw6sCDCtg=";
    android_system_font = "sha256-fjiwsK5py7yp1/c/I3yMJKySrrUOzKq8oQS9hhDDu+k=";
    shared_storage = "sha256-DHCxzSkCxsmqT3w19+bHzsIT+LpR0l7QCrs8rhfr5jk=";
    shizuku_apk_installer = "sha256-od1uMZLDrdjKDghKR4Td4O8Jdfd0WCGOBp8QI+MhwzM=";
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-37-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-37-0
      # plugins compile against their own levels
      platforms-android-36
      platforms-android-35
      ndk-28-2-13676358
      cmake-3-22-1
    ];

  # AGP 9.2.1 needs Gradle >= 9.1 (upstream wrapper pins 9.4.1)
  gradle = pkgs.gradle_9;

  # Two flavors: `normal` (upstream's release) and `fdroid` (hides the
  # self-update source). Without key.properties upstream leaves the release
  # build unsigned and signs separately, so no signing patch is needed.
  gradleTask = ":app:assembleNormalRelease";
  gradleFlags = [
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/37.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];
  apkPath = "build/app/outputs/apk/normal/release/app-normal-release-unsigned.apk";

  verificationMetadata = ./verification-metadata.xml;

  meta = {
    description = "Get Android app updates straight from the source";
    homepage = "https://obtainium.imranr.dev";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "dev.imranr.obtainium";
      versionCode = 2362;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86_64"
      ];
    };
  };
}
