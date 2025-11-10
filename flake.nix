{
  description = "Build android applications with nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    gradle2nix.url = "github:tadfisher/gradle2nix/v2";
    gradle-dot-nix.url = "github:CrazyChaoz/gradle-dot-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
  outputs =
    inputs@{
      self,
      nixpkgs,
      treefmt-nix,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      # although i can only make x86_64-linux work right now
      # but it should be possible to make others work in the future
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      treefmtEval = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        treefmt-nix.lib.evalModule pkgs ./treefmt.nix
      );
    in
    {
      # Export lib overlay for external users to extend their lib with our builders
      overlays.default =
        _final: prev:
        let
          builders = prev.callPackage ./lib/builders/gradle-dot-nix.nix { inherit inputs; };
        in
        {
          lib = prev.lib // {
            inherit (builders) buildGradleApk;
          };
        };

      packages = forAllSystems (
        system:
        let
          pkgsPlain = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
          };
          pkgs = import nixpkgs {
            inherit system;
            config = {
              allowUnfree = true;
              android_sdk.accept_license = true;
            };
            overlays = [ inputs.self.overlays.default ];
          };
          lib = pkgsPlain.callPackage ./lib { inherit inputs; };
          documentation = pkgs.stdenv.mkDerivation {
            pname = "nixapks-docs";
            version = "0.0.1";
            src = ./docs;
            buildInputs = with pkgs; [ mdbook ];
            buildPhase = ''
              mdbook build --dest-dir $out
            '';
          };
        in
        lib.byNameOverlay pkgs ./apks // { inherit documentation; }
      );

      devShells = forAllSystems (
        system:
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
              build-tools-34-0-0
              cmdline-tools-latest
              platform-tools
              platforms-android-36
              platforms-android-34
              platforms-android-35
            ]
          );
        in
        {
          generate-gradle-metadata = pkgs.mkShell {
            name = "gradle-metadata-generator";

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

              # Set up temporary directories
              export TMPDIR=$(mktemp -d)
              export GRADLE_USER_HOME=$TMPDIR/.gradle
              mkdir -p $TMPDIR/aapt2
              export AAPT2_DAEMON_DIR=$TMPDIR/aapt2

              echo "ANDROID_HOME: $ANDROID_HOME"
              echo "JDK_HOME: $JDK_HOME"
              echo "GRADLE_OPTS: $GRADLE_OPTS"
              echo "Gradle version: $(gradle --version | head -n 3)"
              echo ""
              echo "To generate the verification-metadata.xml file:"
              echo ""
              echo "  1. get the gradle task name that generates the release apk, e.g.:"
              echo ""
              echo "     ./gradlew tasks --all | grep assemble"
              echo ""
              echo "     (look for the one with 'Release' in the name)"
              echo ""
              echo "  2. gradle -M sha256 assemblePlayRelease -Dorg.gradle.project.android.aapt2FromMavenOverride=\$ANDROID_HOME/build-tools/36.0.0/aapt2"
              echo ""
            '';
          };
        }
      );

      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;
      });
    };
}
