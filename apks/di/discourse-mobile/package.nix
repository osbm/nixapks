{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApk {
  pname = "discourse-mobile";
  version = "unstable-2025-10-14";

  src = pkgs.fetchFromGitHub {
    owner = "discourse";
    repo = "DiscourseMobile";
    rev = "c803b0c876ecd7246f8f71950fda3dcc625b95c1";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update this hash
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-34-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-34
    ];

  gradleTask = "assembleRelease";
  gradleFlags = [
    "-x lint"
    "-x lintDebug"
    "-x lintRelease"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/34.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];

  verificationMetadata = ./verification-metadata.xml;
  apkPath = "android/app/build/outputs/apk/release/app-release.apk";

  meta = {
    description = "Native iOS and Android app for Discourse";
    homepage = "https://github.com/discourse/DiscourseMobile";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 25;
      targetSdk = 34;
      applicationId = "com.discourse";
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
