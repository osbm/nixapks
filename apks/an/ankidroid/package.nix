{
  pkgs,
  inputs,
  lib,
  abi ? "arm64-v8a", # "armeabi-v7a", "x86", "x86_64"
  flavor ? "full", # "amazon", "play"
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
  # gradle task names capitalise the flavor: assembleFullRelease
  flavorTask = (lib.toUpper (lib.substring 0 1 flavor)) + (lib.substring 1 (-1) flavor);
  # upstream gives every ABI split its own versionCode:
  # <abi digit> * 100000000 + defaultConfig.versionCode (AnkiDroid/build.gradle)
  abiDigit =
    {
      "armeabi-v7a" = 1;
      "x86" = 2;
      "arm64-v8a" = 3;
      "x86_64" = 4;
    }
    .${abi};
  baseVersionCode = 22401300;
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
  '';

  # Release build: without KEYSTOREPATH upstream signs with its public
  # tools/fallback-release-keystore.jks, so no secrets are needed. R8 needs far
  # more heap than upstream's 3G default (GC thrashing otherwise).
  buildPhase = ''
    runHook preBuild

    gradle assemble${flavorTask}Release --info -I ${gradle-init-script} \
      --offline --full-stacktrace -x lint -x lintDebug -x lintRelease -x test --no-daemon \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2 \
      -Dfile.encoding=utf-8 \
      -PbuildTime=1788209187 \
      "-Dorg.gradle.jvmargs=-Xmx10g -XX:MaxMetaspaceSize=1g"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp AnkiDroid/build/outputs/apk/${flavor}/release/AnkiDroid-${flavor}-${abi}-release.apk $out
    runHook postInstall
  '';
  passthru.tests.meta = lib.verifyApkMeta {
    apk = finalAttrs.finalPackage;
    sdk = android-sdk;
  };

  meta = {
    description = "Anki flashcards on Android";
    homepage = "https://ankidroid.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 24;
      targetSdk = 35;
      applicationId = "com.ichi2.anki";
      versionCode = abiDigit * 100000000 + baseVersionCode;
      abis = [ abi ];
    };
    sourceProvenance = [
      lib.sourceTypes.binaryBytecode
      lib.sourceTypes.fromSource
    ];
  };
})
