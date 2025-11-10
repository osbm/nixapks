{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApk {
  pname = "mihon";
  version = "0.19.1";

  src = pkgs.fetchFromGitHub {
    owner = "mihonapp";
    repo = "mihon";
    rev = "v0.19.1";
    hash = "sha256-CaZxJnD2wSQv0bIlu5E2LRG0tq1XNoNXpEVtUHfe7d4=";
    leaveDotGit = true;
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-1
      cmdline-tools-latest
      platform-tools
      platforms-android-35
    ];

  gradleTask = "assembleRelease";
  gradleFlags = [
    "-x lint"
    "-x lintDebug"
    "-x lintRelease"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/35.0.1/aapt2"
    "-Dfile.encoding=utf-8"
    "-Ptelemetry.enabled=false"
  ];

  verificationMetadata = ./verification-metadata.xml;
  apkPath = "app/build/outputs/apk/release/app-universal-release-unsigned.apk";

  extraNativeBuildInputs = [ pkgs.git ];

  meta = {
    description = "An open source flashcard app for spaced repetition learning";
    homepage = "https://mihon.app";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "app.mihon";
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
