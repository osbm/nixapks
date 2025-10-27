{
  pkgs,
  inputs,
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
pkgs.stdenv.mkDerivation rec {
  name = "ankidroid-${version}.apk";
  version = "2.23.0alpha5";

  src = pkgs.fetchFromGitHub {
    owner = "ankidroid";
    repo = "Anki-Android";
    rev = "v${version}";
    hash = "sha256-XFhWQiHvwYkRERJhxqVHP/qWfzOBl/i7nx4vmmYK/vU=";
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
    # Increase JVM heap space for Gradle
    export GRADLE_OPTS="-Xmx6144m -XX:MaxMetaspaceSize=1024m"
  '';

  buildPhase = ''
    gradle assembleDebug --info -I ${gradle-init-script} \
      --offline --full-stacktrace -x lint -x lintDebug -x lintRelease -x test --no-daemon \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2 \
      -Dfile.encoding=utf-8
  '';

  installPhase = ''
    cp AnkiDroid/build/outputs/apk/release/AnkiDroid-release-unsigned.apk $out
  '';
}
