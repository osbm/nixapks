{
  pkgs,
  inputs,
  ...
}:
let
  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      build-tools-34-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-34
    ]
  );
  gradle-init-script =
    (import inputs.gradle-dot-nix {
      inherit pkgs;
      gradle-verification-metadata-file = ./verification-metadata.xml;
    }).gradle-init;
in
pkgs.stdenv.mkDerivation rec {
  name = "smouldering-durtles-${version}.apk";
  version = "1.2.3";

  src = pkgs.fetchFromGitHub {
    owner = "jerryhcooke";
    repo = "smouldering_durtles";
    tag = "v${version}";
    hash = "sha256-xk8xjvUCpHojwdoaBhiXPfX2Tm1iXF8pbphk/FFt1P0=";
  };
  JDK_HOME = "${pkgs.jdk21.home}";
  ANDROID_HOME = "${android-sdk}/share/android-sdk";

  nativeBuildInputs = [
    android-sdk
    pkgs.gradle_8
    pkgs.jdk21
  ];
  buildPhase = ''
    gradle build --info -I ${gradle-init-script} \
      --offline --full-stacktrace -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2
  '';
  installPhase = ''
    cp app/build/outputs/apk/release/app-release.apk $out
  '';
}
