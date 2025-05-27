{
  description = "Build android applications with nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    gradle2nix-flake.url = "github:tadfisher/gradle2nix/v2";
    gradle-dot-nix.url = "github:CrazyChaoz/gradle-dot-nix";
  };
  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        android_sdk.accept_license = true;
      };
      callPackage = pkgs.callPackage;
      stdenv = pkgs.stdenv;

    in
    {
      packages.x86_64-linux.smouldering_durtles =
        callPackage ./apks/sm/smouldering_durtles/package.nix
          {
            inherit (inputs) android-nixpkgs gradle-dot-nix;
          };
    };
}
