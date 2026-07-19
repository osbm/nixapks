{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApk {
  pname = "fossify-keyboard";
  version = "1.9.1";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Keyboard";
    tag = "1.9.1";
    hash = "sha256-t31cp1Ewp3a5Z7ZIOh2vyLVo9EHnF7fjb2zDR3FVdAg=";
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
  apkPath = "app/build/outputs/apk/foss/release/keyboard-14-foss-release-unsigned.apk";

  meta = {
    description = "Keyboard with clipboard history, without ads or tracking";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "org.fossify.keyboard";
      versionCode = 14;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
