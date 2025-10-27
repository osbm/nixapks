{
  description = "Build android applications with nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    gradle2nix.url = "github:tadfisher/gradle2nix/v2";
    gradle-dot-nix.url = "github:CrazyChaoz/gradle-dot-nix";
  };
  outputs =
    inputs@{ nixpkgs, android-nixpkgs, gradle2nix, gradle-dot-nix, ... }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      # although i can only make x86_64-linux work right now
      # but it should be possible to make others work in the future
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          myLib = pkgs.callPackage ./lib { inherit inputs; };
        in
        myLib.byNameOverlay ./apks
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          android-sdk = inputs.android-nixpkgs.sdk.${system} (
            sdkPkgs: with sdkPkgs; [
              build-tools-36-0-0
              build-tools-35-0-0
              cmdline-tools-latest
              platform-tools
              platforms-android-36
            ]
          );
        in
        {
          ankidroid-gradle-metadata = pkgs.mkShell {
            name = "ankidroid-gradle-metadata-generator";

            buildInputs = [
              android-sdk
              pkgs.gradle_8
              pkgs.jdk21
              pkgs.git
            ];

            shellHook = ''
              export ANDROID_HOME="${android-sdk}/share/android-sdk"
              export ANDROID_SDK_ROOT="$ANDROID_HOME"
              export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk-bundle"
              export JDK_HOME="${pkgs.jdk21.home}"
              export JAVA_HOME="${pkgs.jdk21.home}"

              # Override AAPT2 to use the NixOS-compatible version
              # export GRADLE_OPTS="-Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/35.0.0/aapt2"

              # Set up temporary directories
              export TMPDIR=$(mktemp -d)
              export GRADLE_USER_HOME=$TMPDIR/.gradle
              mkdir -p $TMPDIR/aapt2
              export AAPT2_DAEMON_DIR=$TMPDIR/aapt2

              echo "===================================================="
              echo "ankidroid Gradle Metadata Generation Shell"
              echo "===================================================="
              echo ""
              echo "ANDROID_HOME: $ANDROID_HOME"
              echo "JDK_HOME: $JDK_HOME"
              echo "GRADLE_OPTS: $GRADLE_OPTS"
              echo "Gradle version: $(gradle --version | head -n 3)"
              echo ""
              echo "To generate the verification-metadata.xml file:"
              echo ""
              echo "  1. cd /home/osbm/Documents/temp/ankidroid"
              echo "  2. gradle -M sha256 assemblePlayRelease -x lint -x lintDebug -x lintRelease -x test -Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/36.0.0/aapt2"
              echo ""
              echo "This will create gradle/verification-metadata.xml"
              echo "Then copy it to the ankidroid package directory:"
              echo ""
              echo "  3. cp gradle/verification-metadata.xml /home/osbm/Documents/git/nixapks/apks/an/ankidroid/"
              echo ""
              echo "===================================================="
            '';
          };
        }
      );
    };
}
