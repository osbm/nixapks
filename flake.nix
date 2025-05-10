{
  description = "Build android applications with nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:HPRIOR/android-nixpkgs";
    gradle2nix-flake.url = "github:tadfisher/gradle2nix/v2";
    gradle-dot-nix.url = "github:CrazyChaoz/gradle-dot-nix";
  };
  outputs = { self, nixpkgs, ... }:
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
    packages.x86_64-linux.lichess = callPackage ./apks/by-name/li/lichess/package.nix { };
    packages.x86_64-linux.wireguard = callPackage ./apks/by-name/wi/wireguard/package.nix { };
    packages.x86_64-linux.smoking-durtles = callPackage ./apks/by-name/sm/smoking-durtles/package.nix { };
    packages.x86_64-linux.default = self.packages.x86_64-linux.lichess;
  };
}
