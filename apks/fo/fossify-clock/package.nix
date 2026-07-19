{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApk {
  pname = "fossify-clock";
  version = "1.6.0";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Clock";
    tag = "1.6.0";
    hash = "sha256-5SLGFN7IJ6S7mREWsK4Gv9THqHKvkSfovAHGNNaIhvs=";
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-0
      build-tools-36-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-36
    ];

  gradleTask = "assembleFossRelease";
  gradleFlags = [
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/36.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];

  # hashes come from the central lockfile (lib/maven-lock.json)
  apkPath = "app/build/outputs/apk/foss/release/clock-10-foss-release-unsigned.apk";

  meta = {
    description = "Alarm clock with stopwatch and timer, without ads";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "org.fossify.clock";
      versionCode = 10;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
