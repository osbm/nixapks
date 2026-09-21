{
  pkgs,
  inputs,
  lib,
  abi ? "arm64-v8a", # "armeabi-v7a", "x86", "x86_64"
  flavor ? "full", # "amazon", "play"
  # debug/release currently only debug
  ...
}:
let
  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-0
      build-tools-36-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-36
    ]
  );
  gradle-init-script =
    (import inputs.gradle-dot-nix {
      inherit pkgs;
      gradle-verification-metadata-file = ./verification-metadata.xml;
      public-maven-repos = ''
        [
            "https://dl.google.com/dl/android/maven2",
            "https://repo.maven.apache.org/maven2",
            "https://plugins.gradle.org/m2",
            "https://maven.google.com",
            "https://www.jitpack.io"
        ]
      '';
    }).gradle-init;
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  name = "ankidroid-${flavor}-${abi}-${finalAttrs.version}.apk";
  version = "2.24.1";

  src = pkgs.fetchFromGitHub {
    owner = "ankidroid";
    repo = "Anki-Android";
    rev = "v${finalAttrs.version}";
    hash = "sha256-wcw0bt1/4WYQpGSdqbbDd/w7z0KUj0SjAsaHJkzIPO8=";
  };

  JDK_HOME = "${pkgs.jdk21.home}";
  ANDROID_HOME = "${android-sdk}/share/android-sdk";
  ANDROID_NDK_ROOT = "${android-sdk}/share/android-sdk/ndk-bundle";

  nativeBuildInputs = [
    android-sdk
    pkgs.gradle_9
    pkgs.jdk21
    pkgs.git
  ];

  # Upstream reads the commit hash from git at configure time; we build from
  # the plain tarball (no .git), so pin it. Value for v2.24.1.
  postPatch = ''
    substituteInPlace AnkiDroid/build.gradle \
      --replace-fail 'gitCommitHash.get()' '"9f579c10bb151146728220729c510acbbd8faba7"'
  '';

  preBuild = ''
    export TMPDIR=$(mktemp -d)
    export GRADLE_USER_HOME=$TMPDIR/.gradle
    # Ensure AAPT2 has a writable directory
    mkdir -p $TMPDIR/aapt2
    export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
    # Increase JVM heap space for Gradle
    export GRADLE_OPTS="-Xmx6144m -XX:MaxMetaspaceSize=1024m"
  '';

  buildPhase = ''
    gradle assembleDebug --info -I ${gradle-init-script} \
      --offline --full-stacktrace -x lint -x lintDebug -x lintRelease -x test --no-daemon \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2 \
      -Dfile.encoding=utf-8 \
      -PbuildTime=1788209187
  '';

  installPhase = ''
    cp AnkiDroid/build/outputs/apk/${flavor}/debug/AnkiDroid-${flavor}-${abi}-debug.apk $out
  '';
  passthru.tests.meta = lib.verifyApkMeta {
    apk = finalAttrs.finalPackage;
    sdk = android-sdk;
    # debug buildType appends a versionNameSuffix
    version = "${finalAttrs.version}-debug";
  };

  meta = {
    description = "Anki flashcards on Android";
    homepage = "https://ankidroid.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 24;
      targetSdk = 35;
      # debug buildType, which applies an applicationIdSuffix
      applicationId = "com.ichi2.anki.debug";
      abis = [ abi ];
    };
    sourceProvenance = [
      lib.sourceTypes.binaryBytecode
      lib.sourceTypes.fromSource
    ];
  };
})
