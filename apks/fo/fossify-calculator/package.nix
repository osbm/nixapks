{
  pkgs,
  inputs,
  lib,
  ...
}:
let
  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-34
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
  name = "fossify-calculator-${version}.apk";
  version = "1.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Calculator";
    tag = version;
    hash = "sha256-jpPZGFDmn/EVMSEPOXNLAg/PYFMkP/V6+R/pW2h41Vs=";
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
      --offline --no-daemon --full-stacktrace \
      -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/35.0.0/aapt2
  '';
  installPhase = ''
    cp app/build/outputs/apk/foss/release/calculator-7-foss-release-unsigned.apk $out
  '';
  meta = {
    description = "Calculator app without ads";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
  };
}
