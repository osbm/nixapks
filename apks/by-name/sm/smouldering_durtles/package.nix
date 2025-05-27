{lib, pkgs, android-nixpkgs, gradle-dot-nix,...}:
let
  android-sdk = android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (sdkPkgs: with sdkPkgs; [
    # Useful packages for building and testing.
    build-tools-34-0-0
    cmdline-tools-latest
    platform-tools
    platforms-android-34
  ]);
  gradle-init-script =
    (import gradle-dot-nix {
        inherit pkgs;
        gradle-verification-metadata-file = ./verification-metadata.xml;
    }).gradle-init;
in

pkgs.stdenv.mkDerivation rec {
  name = "smouldering-durtles-apk";
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
            pkgs.gradle
            pkgs.jdk21
        ];
        buildPhase = ''
          gradle build --info -I ${gradle-init-script} --offline --full-stacktrace -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/34.0.0/aapt2
        '';
        installPhase = ''
          mkdir -p $out
          cp -r ./app/build/outputs/apk/release/app-release-unsigned.apk $out
        '';
}

