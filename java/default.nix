{ pkgs }:
let
  inherit (pkgs) lib;
  builders = pkgs.callPackage ../lib/builders/build-maven-jar.nix { };
  callPackage = lib.callPackageWith (pkgs // { inherit (builders) buildMavenJar; } // packages);
  packages = {
    javax-inject = callPackage ./packages/javax-inject/package.nix { };
    jsr305 = callPackage ./packages/jsr305/package.nix { };
    jetbrains-annotations = callPackage ./packages/jetbrains-annotations/package.nix { };
    jspecify = callPackage ./packages/jspecify/package.nix { };
    slf4j-api = callPackage ./packages/slf4j-api/package.nix { };
    jsoup = callPackage ./packages/jsoup/package.nix { };
  };
in
packages
// {
  # All source-built artifacts composed into one Maven-repository-layout
  # directory, usable as an offline repository or as an overlay that
  # shadows binary artifacts in a bigger repo.
  maven-repo = pkgs.symlinkJoin {
    name = "nixjars-maven-repo";
    paths = lib.attrValues packages;
  };
}
