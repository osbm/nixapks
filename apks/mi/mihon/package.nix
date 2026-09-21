{
  pkgs,
  lib,
  ...
}:
lib.buildGradleApkGradleDotNix {
  pname = "mihon";
  version = "0.20.4";

  src = pkgs.fetchFromGitHub {
    owner = "mihonapp";
    repo = "mihon";
    rev = "v0.20.4";
    hash = "sha256-PZUyqdgXa3971Ct8aBmmsrF2US+tdAjVwdPbg86tWMw=";
  };

  androidSdkPackages =
    sdkPkgs: with sdkPkgs; [
      build-tools-36-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-37-0
    ];

  # AGP 9.3.1 (upstream wrapper pins Gradle 9.6.1)
  gradle = pkgs.gradle_9;

  gradleTask = "assembleRelease";
  gradleFlags = [
    "-x"
    "lint"
    "-x"
    "lintDebug"
    "-x"
    "lintRelease"
    "-Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/36.0.0/aapt2"
    "-Dfile.encoding=utf-8"
  ];

  preBuild = ''
    # Backport of upstream 737fdbfb "Switch to upstream FlexibleAdapter"
    # (mihonapp/mihon#3932): JitPack can no longer serve the arkon fork, the
    # same library is on Maven Central. Drop once a release contains it.
    substituteInPlace gradle/libs.versions.toml \
      --replace-fail 'flexibleAdapter = "c8013533"' 'flexibleAdapter = "5.1.0"' \
      --replace-fail 'com.github.arkon.FlexibleAdapter:flexible-adapter' 'eu.davidea:flexible-adapter'

    # Upstream derives these from the git repo at configure time (leaveDotGit
    # is a reproducibility hazard, so we build from the plain tarball instead).
    # Values pinned for v0.20.4: 7872 commits, commit df6507256, committed
    # 2026-08-05T16:27:07Z. Pinning BUILD_TIME also makes it deterministic.
    substituteInPlace app/build.gradle.kts \
      --replace-fail 'getLatestCommitCount()' '"7872"' \
      --replace-fail 'getLatestCommitSha()' '"df6507256"' \
      --replace-fail 'getBuildTime(useLatestCommitTime = true)' '"2026-08-05T16:27:07Z"' \
      --replace-fail 'getBuildTime(useLatestCommitTime = false)' '"2026-08-05T16:27:07Z"'
  '';

  verificationMetadata = ./verification-metadata.xml;
  apkPath = "app/build/outputs/apk/release/app-universal-release.apk";

  meta = {
    description = "Free and open source manga reader for Android";
    homepage = "https://mihon.app";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      applicationId = "app.mihon";
      versionCode = 29;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
  };
}
