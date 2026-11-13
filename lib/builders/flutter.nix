{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  # Flutter apps. Two dependency worlds, two lock files:
  #  - Dart packages come from pubspec.lock through nixpkgs' pub2nix machinery
  #    (buildDartApplication with the Flutter SDK standing in for the Dart SDK),
  #  - Java/Kotlin artifacts come from a per-app verification-metadata.xml
  #    through gradle-dot-nix, exactly like the Gradle apps.
  # Gradle drives the whole build: the Flutter Gradle plugin shells out to
  # `flutter assemble` for the Dart AOT compile, so this is the plain Gradle
  # recipe plus a writable copy of the Flutter SDK (the plugin is an included
  # build inside the SDK and writes its own build output there).
  buildFlutterApk =
    {
      pname,
      version,
      # pubspec.lock converted to JSON (`yq . pubspec.lock > pubspec.lock.json`).
      # Hashes of git-sourced pub dependencies, keyed by package name
      # (pub does not record them).
      flutter ? pkgs.flutter,
      # Dart build hooks (hook/build.dart) of some packages download a prebuilt
      # native library per ABI at build time (sqlite3, powersync, ...). They
      # cache it under .dart_tool/hooks_runner/shared/<package>/build/
      # download-<first 8 hex of sha256>/<fileName> and reuse a cached file whose
      # hash matches, so that cache is pre-seeded from fetchurl:
      #   { sqlite3 = { fileName = "libsqlite3.so"; files = { "<url>" = "<sha256>"; }; }; }
      # Upstream lists the expected hashes next to the hook (hex works as-is).
      hookDownloads ? { },
      # Android SDK configuration. Native plugins each pin an ndkVersion and
      # AGP refuses to build without that exact one, so list every NDK the
      # plugins ask for.
      androidSdkPackages,
      # Gradle configuration (run with -p android)
      # :app only: a bare assembleRelease also builds dev-only plugin projects
      # (integration_test) that release builds do not use, and those pull in
      # dynamic versions (androidx.test:runner:1.2+) nothing can serve offline.
      gradleTask ? ":app:assembleRelease",
      gradleFlags ? [ ],
      verificationMetadata,
      mavenRepos ? ''
        [
            "https://dl.google.com/dl/android/maven2",
            "https://repo.maven.apache.org/maven2",
            "https://plugins.gradle.org/m2",
            "https://maven.google.com",
            "https://www.jitpack.io",
            "https://storage.googleapis.com/download.flutter.io"
        ]
      '',
      apkPath ? "build/app/outputs/apk/release/app-release.apk",
      # Passed to `flutter build` as --build-name / --build-number; null
      # means the `version: name+code` line of pubspec.yaml.
      versionName ? null,
      versionCode ? null,
      jdk ? pkgs.jdk21,
      # Same default as the Gradle builders; AGP >= 9 needs pkgs.gradle_9. The
      # metadata must be generated with the same Gradle major.
      gradle ? pkgs.gradle_8,
      meta ? { },
      ...
    }@args:
    let
      inherit ((import ./verify-apk-meta.nix { inherit pkgs lib; })) verifyApkMeta;

      android-sdk = inputs.android-nixpkgs.sdk.${pkgs.stdenv.hostPlatform.system} androidSdkPackages;

      # Only the Android engine artifacts; the default wrapper also drags in
      # the Linux desktop toolchain (gtk & co).
      flutterSdk = flutter.override {
        supportedTargetFlutterPlatforms = [
          "universal"
          "android"
        ];
      };

      buildDartApplication = pkgs.buildDartApplication.override { dart = flutterSdk; };

      gradle-init-script =
        (import inputs.gradle-dot-nix {
          inherit pkgs;
          gradle-verification-metadata-file = verificationMetadata;
          public-maven-repos = mavenRepos;
        }).gradle-init;

      # Pub needs SSL certificates and Dart does not respect SSL_CERT_FILE;
      # nixpkgs patches Flutter to take the Dart binary used for pub from
      # NIX_FLUTTER_PUB_DART (copied from nixpkgs' buildFlutterApplication).
      dartWithCerts = pkgs.runCommand "dart-with-certs" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
        mkdir -p "$out/bin"
        makeWrapper ${flutterSdk.dart}/bin/dart "$out/bin/dart" \
          --add-flags "--root-certs-file=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      '';

      # nixpkgs ships source builders for a few pub packages that patch their
      # Linux desktop CMake files to use system libraries. They are useless for
      # an Android build and fail on packages without a linux/ directory, so
      # every default builder is replaced by the identity; apps can still pass
      # their own.
      linuxOnlySourceBuilders = lib.mapAttrs (_: _: ({ src, ... }: src)) (
        pkgs.callPackage "${pkgs.path}/pkgs/development/compilers/dart/package-source-builders" { }
      );

      hookDownloadsScript = lib.concatStrings (
        lib.mapAttrsToList (
          package:
          { fileName, files }:
          lib.concatStrings (
            lib.mapAttrsToList (url: hash: ''
              d=.dart_tool/hooks_runner/shared/${package}/build/download-${
                builtins.substring 0 8 (
                  builtins.convertHash {
                    inherit hash;
                    hashAlgo = "sha256";
                    toHashFormat = "base16";
                  }
                )
              }
              mkdir -p $d
              cp ${
                pkgs.fetchurl {
                  inherit url;
                  hash = builtins.convertHash {
                    inherit hash;
                    hashAlgo = "sha256";
                    toHashFormat = "sri";
                  };
                }
              } $d/${fileName}
            '') files
          )
        ) hookDownloads
      );

      ownArgs = [
        "flutter"
        "androidSdkPackages"
        "hookDownloads"
        "gradleTask"
        "gradleFlags"
        "verificationMetadata"
        "mavenRepos"
        "apkPath"
        "versionName"
        "versionCode"
        "jdk"
        "gradle"
        "meta"
      ];
    in
    buildDartApplication (
      finalAttrs:
      (builtins.removeAttrs args ownArgs)
      // {
        inherit pname version;
        name = "${pname}-${version}.apk";
        customSourceBuilders = linuxOnlySourceBuilders // (args.customSourceBuilders or { });

        nativeBuildInputs = (args.nativeBuildInputs or [ ]) ++ [
          android-sdk
          gradle
          jdk
          pkgs.lndir
          pkgs.yq
        ];

        sdkSetupScript = ''
          export NIX_FLUTTER_PUB_DART="${dartWithCerts}/bin/dart"
          export HOME="$NIX_BUILD_TOP"
          flutter config --no-analytics &>/dev/null # mute first-run
        '';

        # https://github.com/dart-lang/pub/blob/68dc2f547d0a264955c1fa551fa0a0e158046494/lib/src/sdk/flutter.dart#L81
        sdkSourceBuilders = {
          "flutter" =
            name:
            pkgs.runCommand "flutter-sdk-${name}" { passthru.packageRoot = "."; } ''
              for path in '${flutterSdk}/packages/${name}' '${flutterSdk}/bin/cache/pkg/${name}'; do
                if [ -d "$path" ]; then
                  ln -s "$path" "$out"
                  break
                fi
              done

              if [ ! -e "$out" ]; then
                echo 1>&2 'The Flutter SDK does not contain the requested package: ${name}!'
                exit 1
              fi
            '';
        };

        # The dart hooks would compile bin/*.dart and install a pub cache;
        # Gradle does the building here and the output is a single apk.
        dontDartBuild = true;
        dontDartInstall = true;
        dontDartInstallCache = true;

        buildPhase = ''
          runHook preBuild

          export TMPDIR=$(mktemp -d)
          export GRADLE_USER_HOME=$TMPDIR/.gradle
          mkdir -p $TMPDIR/aapt2
          export AAPT2_DAEMON_DIR=$TMPDIR/aapt2
          export ANDROID_HOME=${android-sdk}/share/android-sdk
          export ANDROID_SDK_ROOT=$ANDROID_HOME
          export JAVA_HOME=${jdk.home}

          # Everything `flutter build apk --release` prepares before it would
          # call Gradle: android/local.properties, the release-mode
          # GeneratedPluginRegistrant (dev-only plugins such as
          # integration_test are left out of release builds, and Gradle
          # drops them too, so a registrant from `pub get` would not
          # compile), generated localizations. The pub step is skipped
          # because the package config was generated by pub2nix.
          # Every Flutter plugin becomes a Gradle subproject whose directory is
          # the pub package: a read-only store path. Gradle 9 refuses to
          # configure such projects, AGP stages native builds inside them and
          # some plugins write generated files next to their sources. Copy the
          # packages that carry an android/ project somewhere writable and
          # point package_config.json there (the Flutter tool derives the
          # plugin list from it).
          chmod u+w .dart_tool/package_config.json
          mkdir -p $NIX_BUILD_TOP/pub-plugins
          for uri in $(jq -r '.packages[] | select(.rootUri | startswith("file:///nix/store")) | .rootUri' .dart_tool/package_config.json); do
            p=''${uri#file://}
            p=''${p%/}
            p=''${p%/.}
            if [ -d "$p/android" ]; then
              dest=$NIX_BUILD_TOP/pub-plugins/$(basename "$p")
              cp -rL --no-preserve=mode "$p" "$dest"
              jq --arg from "$uri" --arg to "file://$dest/" \
                '(.packages[] | select(.rootUri == $from) | .rootUri) = $to' \
                .dart_tool/package_config.json > $NIX_BUILD_TOP/package_config.tmp
              mv $NIX_BUILD_TOP/package_config.tmp .dart_tool/package_config.json
            fi
          done

          ${hookDownloadsScript}

          # `flutter pub get` would also have generated these; the pub step is
          # skipped (see below).
          if [ "$(yq -r '.flutter.generate // false' pubspec.yaml)" = "true" ]; then
            flutter gen-l10n
          fi

          flutter build apk --release --config-only \
            ${lib.optionalString (versionName != null) "--build-name=${versionName}"} \
            ${lib.optionalString (versionCode != null) "--build-number=${toString versionCode}"}
          # The Flutter Gradle plugin is an included build inside the SDK and
          # writes its build output next to its sources: hand Gradle a
          # writable tree of symlinks instead of the store path.
          mkdir $TMPDIR/flutter-sdk
          lndir -silent ${flutterSdk} $TMPDIR/flutter-sdk
          sed -i "s|^flutter.sdk=.*|flutter.sdk=$TMPDIR/flutter-sdk|" android/local.properties

          gradle -p android ${gradleTask} --info -I ${gradle-init-script} -I ${./flutter-init.gradle} \
            --offline --no-daemon --full-stacktrace \
            -Dorg.gradle.java.installations.paths=$JAVA_HOME \
            ${lib.concatStringsSep " " gradleFlags}

          runHook postBuild
        '';

        installPhase = ''
          runHook preInstall
          cp ${apkPath} $out
          # buildDartApplication insists on this output; it must stay empty
          # because the apk may not reference the store (allowedReferences).
          mkdir -p $pubcache
          runHook postInstall
        '';

        passthru =
          (args.passthru or { })
          // lib.optionalAttrs (meta ? android) {
            tests.meta = verifyApkMeta {
              apk = finalAttrs.finalPackage;
              sdk = android-sdk;
              inherit version;
              inherit (meta) android;
            };
          };

        meta = meta // {
          sourceProvenance = [
            lib.sourceTypes.binaryBytecode
            lib.sourceTypes.fromSource
          ]
          ++ lib.optional (hookDownloads != { }) lib.sourceTypes.binaryNativeCode;
        };
      }
    );
}
