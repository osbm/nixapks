{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApkCentralizedLock {
  pname = "fossify-paint";
  version = "1.4.0";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Paint";
    tag = "1.4.0";
    hash = "sha256-9XAdE5+ZCL7mxI/CgJaD+cDGf+l0csAohr+QpMtdaUE=";
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
  apkPath = "app/build/outputs/apk/foss/release/paint-7-foss-release-unsigned.apk";

  meta = {
    description = "Drawing app for sketching and doodling, without ads";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "org.fossify.paint";
      versionCode = 7;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
