{
  pkgs,
  lib,
  ...
}:
# First Flutter app in the repo (buildFlutterApk).
lib.buildFlutterApk {
  pname = "wger";
  version = "2.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "wger-project";
    repo = "flutter";
    tag = "2.1.0";
    hash = "sha256-f9JmyQnlWyqjUw6hriDQFAUyB0vMGxLNmK+b5gMy5WI=";
  };

  # upstream CI pins 3.44.9; nixpkgs has 3.44.4, pubspec.lock wants >=3.44.0
  flutter = pkgs.flutter344;

  pubspecLock = lib.importJSON ./pubspec.lock.json;
  gitHashes = {
    health_bridge = "sha256-/0um3RIDTxuA/pIsxFJP03Ln8BrHNFRGZo2NMUan97o=";
  };

  # The release signing config reads a keystore that only upstream's CI has;
  # without it AGP aborts. Sign with the debug key like the other apps.
  postPatch = ''
    substituteInPlace android/app/build.gradle \
      --replace-fail "signingConfig signingConfigs.release" "signingConfig signingConfigs.debug"
  '';

  # sqlite3 and powersync fetch a prebuilt native library per ABI from their
  # GitHub releases at build time (Dart build hooks); hashes are the ones
  # the packages verify against (sqlite3: lib/src/hook/asset_hashes.dart,
  # powersync: lib/src/setup/native.dart).
  hookDownloads = {
    sqlite3 = {
      fileName = "libsqlite3.so";
      files = {
        "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm.android.so" =
          "a42fa9d0f5c006d30b000d4904bc497705191c5d7330b178618546004295bb49";
        "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.arm64.android.so" =
          "0c2d3bfc8c87abceb21ed72a4bb49964121c5fe1a8ef3848d83ba907d01b6161";
        "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-3.5.2/libsqlite3.x64.android.so" =
          "949965f0eba976f707ae364cdcb42c342b5f0626081f8d7f0378fb7b52848772";
      };
    };
    powersync = {
      fileName = "libpowersync_core.so";
      files = {
        "https://github.com/powersync-ja/powersync-sqlite-core/releases/download/v0.5.1/libpowersync_armv7.android.so" =
          "503dc7002dd13fcaac37ff90520a6567c4ba38cc26b06a5b56ba89df129ed7a9";
        "https://github.com/powersync-ja/powersync-sqlite-core/releases/download/v0.5.1/libpowersync_aarch64.android.so" =
          "92a3bdf2e0fabb1b46ab420a6aa4c62487cf07596afa87b8ab7c0b82eca658a0";
        "https://github.com/powersync-ja/powersync-sqlite-core/releases/download/v0.5.1/libpowersync_x64.android.so" =
          "02f9e1d87bb26a8119bd14c3d9691ea93337d1057966464983179419703e2cad";
      };
    };
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-37-0-0
      # AGP 8.13 default build-tools (R8 wants them)
      build-tools-35-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-37-0
      # plugins compile against their own levels
      platforms-android-36
      platforms-android-35
      platforms-android-34
      # app + jni plugin
      ndk-28-2-13676358
      # flutter_zxing pins its own
      ndk-27-0-12077973
      cmake-3-22-1
    ];

  gradleFlags = [
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/37.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];

  verificationMetadata = ./verification-metadata.xml;

  meta = {
    description = "Workout, nutrition and weight manager (client for a wger server)";
    homepage = "https://wger.de";
    license = lib.licenses.agpl3Plus;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "de.wger.flutter";
      versionCode = 270;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86_64"
      ];
    };
  };
}
