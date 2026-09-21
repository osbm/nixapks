{
  pkgs,
  inputs,
  lib,
  ...
}:
# First React Native (Expo) app in the repo. Everything is built from source
# in one offline derivation: pnpm install -> lingui compile -> expo prebuild
# -> gradle :app:assembleRelease (React Native and Hermes are compiled from
# source because upstream's production config sets buildReactNativeFromSource
# and patches ReactAndroid).
let
  version = "1.128.0";

  android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} (
    sdkPkgs: with sdkPkgs; [
      build-tools-35-0-0
      build-tools-36-0-0
      cmdline-tools-latest
      platform-tools
      platforms-android-35
      platforms-android-36
      ndk-27-1-12297006
      # ReactAndroid/hermes want 3.30.5, third-party RN libraries 3.22.1
      cmake-3-30-5
      cmake-3-22-1
    ]
  );

  src = pkgs.fetchFromGitHub {
    owner = "bluesky-social";
    repo = "social-app";
    tag = version;
    hash = "sha256-dSMJOd+G/l2/gafgtlLWj5YMRdn46z5ovcNexy1dSjo=";
  };

  pnpmDeps = pkgs.fetchPnpmDeps {
    pname = "bluesky";
    inherit version src;
    pnpm = pkgs.pnpm_11;
    fetcherVersion = 4;
    hash = "sha256-xHm6Tr4BUN8d55GJ6JTPTrdiM94ZINglWfvLcsLJXXs=";
  };

  # Source tarballs ReactAndroid downloads at build time. It looks in
  # REACT_NATIVE_DOWNLOADS_DIR first, under exactly these file names.
  rnDownloads = pkgs.linkFarm "react-native-downloads" (
    lib.mapAttrsToList
      (name: v: {
        inherit name;
        path = pkgs.fetchurl {
          inherit name;
          inherit (v) url hash;
        };
      })
      {
        "boost_1_83_0.tar.gz" = {
          url = "https://archives.boost.io/release/1.83.0/source/boost_1_83_0.tar.gz";
          hash = "sha256-wGhbaN1EzEZXTM6GxOF8D2EbFeGVvphI39B2mgogdig=";
        };
        "double-conversion-1.1.6.tar.gz" = {
          url = "https://github.com/google/double-conversion/archive/v1.1.6.tar.gz";
          hash = "sha256-a4UKzY6IUVdkRyxSlzJ3dEqUX5p2mpOWjvxC7+9k1no=";
        };
        "folly-2024.11.18.00.tar.gz" = {
          url = "https://github.com/facebook/folly/archive/v2024.11.18.00.tar.gz";
          hash = "sha256-ssaHm6i6YlIY0aue78wWEakAPQW8LLGjjzuuIYkuUWc=";
        };
        "fast_float-8.0.0.tar.gz" = {
          url = "https://github.com/fastfloat/fast_float/archive/v8.0.0.tar.gz";
          hash = "sha256-8xLy3DTGHmZfSxMsAwfW9wrZQgGF+oMZEbwkQIrPYl0=";
        };
        "fmt-11.0.2.tar.gz" = {
          url = "https://github.com/fmtlib/fmt/archive/11.0.2.tar.gz";
          hash = "sha256-bLHm03vct1bbvlm+Q4eQ20Cc20hoxm6IjV358T98An8=";
        };
        "glog-0.3.5.tar.gz" = {
          url = "https://github.com/google/glog/archive/v0.3.5.tar.gz";
          hash = "sha256-dYDkCKLAtaicohRzmXjOb/SAtefY12mKKqkvrcSE0eA=";
        };
        # node_modules/react-native/sdks/.hermesversion
        "hermes.tar.gz" = {
          url = "https://github.com/facebook/hermes/tarball/hermes-2025-07-07-RNv0.81.0-e0fc67142ec0763c6b6153ca2bf96df815539782";
          hash = "sha256-aWya0E5d7hv4oKb0ZFp+4h6OKTfFzjrIJK4usbCXK40=";
        };
      }
  );

  # node_modules + generated locales + expo prebuild (the android/ project).
  # Shared by the final build and by expoLocalRepos below.
  jsAttrs = {
    inherit version src pnpmDeps;
    nativeBuildInputs = [
      pkgs.nodejs_24
      pkgs.pnpm_11
      pkgs.pnpmConfigHook
      pkgs.git
    ];
    dontFixup = true;
  };

  # Expo modules ship prebuilt AARs in node_modules/*/local-maven-repo. Gradle
  # verifies them, so they are in verification-metadata.xml, but no server
  # hosts them: hand them to gradle-dot-nix as local repos.
  expoLocalRepos = pkgs.stdenv.mkDerivation (
    jsAttrs
    // {
      pname = "bluesky-expo-local-maven-repos";
      dontBuild = true;
      installPhase = ''
        mkdir -p $out
        for d in node_modules/*/local-maven-repo node_modules/@*/*/local-maven-repo; do
          if [ -d "$d" ]; then cp -r "$d" "$out/$(echo "$d" | tr / _)"; fi
        done
      '';
    }
  );

  # gradle-dot-nix bug: the .module derivation looks up the *.aar* file name
  # in local-maven-repos and copies the AAR as the .module (hash mismatch).
  gradle-dot-nix-patched = pkgs.applyPatches {
    name = "gradle-dot-nix-patched";
    src = inputs.gradle-dot-nix;
    patches = [ ./gradle-dot-nix-local-module.patch ];
  };

  gradle-init-script =
    (import gradle-dot-nix-patched {
      inherit pkgs;
      gradle-verification-metadata-file = ./verification-metadata.xml;
      local-maven-repos = [ expoLocalRepos ];
      public-maven-repos = ''
        [
            "https://dl.google.com/dl/android/maven2",
            "https://repo.maven.apache.org/maven2",
            "https://plugins.gradle.org/m2",
            "https://maven.google.com",
            "https://www.jitpack.io",
            "https://dl.bitdrift.io/sdk/android-maven"
        ]
      '';
    }).gradle-init;
in
pkgs.stdenv.mkDerivation (
  finalAttrs:
  jsAttrs
  // {
    name = "bluesky-${version}.apk";

    nativeBuildInputs = jsAttrs.nativeBuildInputs ++ [
      android-sdk
      pkgs.gradle_8
      pkgs.jdk17
      # host build of hermesc
      pkgs.gnumake
      pkgs.ninja
      pkgs.python3
      pkgs.pkg-config
    ];

    env = {
      EXPO_PUBLIC_ENV = "production";
      EAS_BUILD_PLATFORM = "android";
      EXPO_NO_GIT_STATUS = "1";
      EXPO_NO_TELEMETRY = "1";
      CI = "1";
      NODE_ENV = "production";
      # boost's tarball has non-ASCII file names; without a UTF-8 locale
      # gradle's tarTree dies with MalformedInputException
      LANG = "C.UTF-8";
      LC_ALL = "C.UTF-8";
    };

    buildPhase = ''
      runHook preBuild

      export HOME=$TMPDIR
      # upstream keeps the real firebase config out of the repo; the example
      # has the right shape and expo prebuild fails without the file
      cp google-services.json.example google-services.json
      # src/locale/locales/*/messages.ts are generated (upstream: intl:compile)
      pnpm exec lingui compile
      pnpm exec expo prebuild --platform android --no-install

      export ANDROID_HOME=${android-sdk}/share/android-sdk
      export ANDROID_SDK_ROOT=$ANDROID_HOME
      export JAVA_HOME=${pkgs.jdk17.home}
      export GRADLE_USER_HOME=$TMPDIR/.gradle
      mkdir -p $TMPDIR/aapt2
      export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
      # hermesc is built for the host and links icu
      export CMAKE_PREFIX_PATH=${pkgs.icu.dev}:${pkgs.icu.out}:${pkgs.zlib.dev}:${pkgs.zlib.out}
      export LD_LIBRARY_PATH=${pkgs.icu.out}/lib:${pkgs.zlib.out}/lib
      mkdir -p $TMPDIR/rn-downloads
      cp -L ${rnDownloads}/* $TMPDIR/rn-downloads/
      export REACT_NATIVE_DOWNLOADS_DIR=$TMPDIR/rn-downloads

      cd android
      gradle :app:assembleRelease -I ${gradle-init-script} \
        --offline --no-daemon --full-stacktrace \
        -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/35.0.0/aapt2 \
        -Dorg.gradle.java.installations.paths=$JAVA_HOME \
        -Dfile.encoding=utf-8
      cd ..

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      cp android/app/build/outputs/apk/release/app-release.apk $out
      runHook postInstall
    '';

    passthru.tests.meta = lib.verifyApkMeta {
      apk = finalAttrs.finalPackage;
      sdk = android-sdk;
      inherit version;
    };

    meta = {
      description = "Bluesky social app (AT Protocol client)";
      homepage = "https://bsky.app";
      license = lib.licenses.mit;
      maintainers = with lib.maintainers; [ osbm ];
      android = {
        minSdk = 24;
        targetSdk = 35;
        applicationId = "xyz.blueskyweb.app";
        # upstream sets the real versionCode in their CI (EAS build number);
        # a plain source build gets 1
        versionCode = 1;
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
  }
)
