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
    };
}
