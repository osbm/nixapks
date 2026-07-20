{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApkGradleDotNix {
  pname = "mihon";
  version = "0.19.1";

  src = pkgs.fetchFromGitHub {
    owner = "mihonapp";
    repo = "mihon";
    rev = "v0.19.1";
    hash = "sha256-1B4NQFrSjFBeI0d3LptkgHqyn7ojf3PPcI9P+LeNTO4=";
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
    "-x"
    "lint"
    "-x"
    "lintDebug"
    "-x"
    "lintRelease"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/35.0.1/aapt2"
    "-Dfile.encoding=utf-8"
    "-Ptelemetry.enabled=false"
  ];

  # Upstream derives these from the git repo at configure time (leaveDotGit
  # is a reproducibility hazard, so we build from the plain tarball instead).
  # Values pinned for v0.19.1: 7357 commits, commit 029e36b, committed
  # 2025-08-07T13:59:01Z. Pinning BUILD_TIME also makes it deterministic.
  preBuild = ''
    substituteInPlace app/build.gradle.kts \
      --replace-fail 'getCommitCount()' '"7357"' \
      --replace-fail 'getGitSha()' '"029e36b"' \
      --replace-fail 'getBuildTime(useLastCommitTime = true)' '"2025-08-07T13:59:01Z"' \
      --replace-fail 'getBuildTime(useLastCommitTime = false)' '"2025-08-07T13:59:01Z"'
  '';

  verificationMetadata = ./verification-metadata.xml;
  apkPath = "app/build/outputs/apk/release/app-universal-release-unsigned.apk";

  extraNativeBuildInputs = [ pkgs.git ];

  meta = {
    description = "Free and open source manga reader for Android";
    homepage = "https://mihon.app";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      # v0.19.1 really targets 34 (verified against the apk by tests.meta)
      targetSdk = 34;
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
