{
  pkgs,
  inputs,
  ...
}:
let
  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
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
  name = "fossify-notes-${version}.apk";
  version = "1.5.0";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "notes";
    tag = version;
    hash = "sha256-kh+O6ETP7XvPq+rtSH5mMSLbV7UpOE+HKx2zaALVK8c=";
  };
  JDK_HOME = "${pkgs.jdk21.home}";
  ANDROID_HOME = "${android-sdk}/share/android-sdk";

  nativeBuildInputs = [
    android-sdk
    pkgs.gradle_8
    pkgs.jdk21
  ];
  buildPhase = ''
    gradle assembleFossRelease --info -I ${gradle-init-script} \
      --offline --full-stacktrace -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/36.0.0/aapt2
  '';
  installPhase = ''
    cp app/build/outputs/apk/release/app-release.apk $out
  '';
}
