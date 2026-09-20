{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApkGradleDotNix {
  pname = "fossify-voice-recorder";
  version = "1.7.1";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Voice-Recorder";
    tag = "1.7.1";
    hash = "sha256-1Ui/n5pnWnYwA9rnfVGa17iJlYVA/oY+2UAM7McPw5c=";
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-36-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-36
    ];

  # AGP 9.0.1 needs Gradle >= 9.1 (upstream wrapper pins 9.3.1)
  gradle = pkgs.gradle_9;

  gradleTask = "assembleFossRelease";
  gradleFlags = [
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/36.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];

  verificationMetadata = ./verification-metadata.xml;
  apkPath = "app/build/outputs/apk/foss/release/voicerecorder-18-foss-release-unsigned.apk";

  meta = {
    description = "Voice recorder without ads";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "org.fossify.voicerecorder";
      versionCode = 18;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
