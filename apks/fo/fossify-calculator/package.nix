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
  name = "fossify-calculator-${finalAttrs.version}.apk";
  version = "1.4.0";

  src = pkgs.fetchFromGitHub {
    owner = "FossifyOrg";
    repo = "Calculator";
    tag = finalAttrs.version;
    hash = "sha256-emMTUn7mb3Y6OX60N3KK/RVdTxXxvcny0s4K0ERVrAA=";
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
    cp app/build/outputs/apk/foss/release/calculator-10-foss-release-unsigned.apk $out
  '';
  passthru.tests.meta = lib.verifyApkMeta {
    apk = finalAttrs.finalPackage;
    sdk = android-sdk;
  };

  meta = {
    description = "Calculator app without ads";
    homepage = "https://fossify.org";
    license = lib.licenses.gpl3;
    maintainers = with lib.maintainers; [ osbm ];
    android = {
      minSdk = 26;
      targetSdk = 36;
      # upstream APP_ID really is org.fossify.math
      applicationId = "org.fossify.math";
      versionCode = 10;
      abis = [
        "armeabi-v7a"
        "arm64-v8a"
        "x86"
        "x86_64"
      ];
    };
    sourceProvenance = [
      lib.sourceTypes.binaryBytecode
      lib.sourceTypes.fromSource
    ];
  };
})
