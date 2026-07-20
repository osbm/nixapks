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
  inherit ((import ./compare-with-central.nix { inherit pkgs lib; })) compareWithCentral;

  # sha256 of the binary jar as published on Maven Central, per package.
  # Used by the verification harness; add an entry for every new package.
  centralHashes = {
    javax-inject = "sha256-kcdwRKUMSBY2wy2Rb9ickRinIZU5BFLIEGUID5V95/8=";
    jsr305 = "sha256-dmrSoHg/JoeWLIrXTO7MOKKLn3Ki0IXuQ4t4E+ko0Mc=";
    jetbrains-annotations = "sha256-ew8ZckCCy/y8ZuWr6iubySzwih6hHhkZM+1DgB6zzQU=";
    jspecify = "sha256-H61ua+dVd4Hk0zcp1Jrhzcj92m/kd7sMxozjUer9+6s=";
    slf4j-api = "sha256-XWKYuToZBcMs2mR4gIrBTC1KR+kVNeU8Qff+64XZRvQ=";
    jsoup = "sha256-8FSW4lVzR1nw1LVjLaeyT4ExMUfHjGnpCtBF0JYZE0Q=";
  };

  centralReports = lib.mapAttrs (
    name: centralHash:
    compareWithCentral {
      pkg = packages.${name};
      inherit centralHash;
    }
  ) centralHashes;
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

  # Per-package comparison against the Maven Central binaries, plus one
  # concatenated report: nix build .#javaPackages.central-report
  reports = centralReports;
  central-report = pkgs.concatText "nixjars-central-report" (
    lib.mapAttrsToList (_: r: r) centralReports
  );
}
