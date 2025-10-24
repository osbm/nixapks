{
  pkgs,
  inputs,
  ...
}:
let
  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-1
      cmdline-tools-latest
      platform-tools
      platforms-android-35
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
pkgs.stdenv.mkDerivation rec {
  name = "mihon-${version}.apk";
  version = "0.19.1";

  src = pkgs.fetchFromGitHub {
    owner = "mihonapp";
    repo = "mihon";
    rev = "v${version}";
    hash = "sha256-CaZxJnD2wSQv0bIlu5E2LRG0tq1XNoNXpEVtUHfe7d4=";
    leaveDotGit = true;
  };

  JDK_HOME = "${pkgs.jdk21.home}";
  ANDROID_HOME = "${android-sdk}/share/android-sdk";
  ANDROID_NDK_ROOT = "${ANDROID_HOME}/ndk-bundle";

  nativeBuildInputs = [
    android-sdk
    pkgs.gradle_8
    pkgs.jdk21
    pkgs.git
  ];

  preBuild = ''
    export TMPDIR=$(mktemp -d)
    export GRADLE_USER_HOME=$TMPDIR/.gradle
    # Ensure AAPT2 has a writable directory
    mkdir -p $TMPDIR/aapt2
    export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
  '';

  buildPhase = ''
    gradle assembleRelease --info -I ${gradle-init-script} \
      --offline --full-stacktrace -x lint -x lintDebug -x lintRelease \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/35.0.1/aapt2 \
      -Dfile.encoding=utf-8 -Ptelemetry.enabled=false
  '';

  installPhase = ''
    cp app/build/outputs/apk/release/app-universal-release-unsigned.apk $out
  '';
}
