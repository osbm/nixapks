{
  description = "Build android applications with nix";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    android-nixpkgs.url = "github:tadfisher/android-nixpkgs";
    gradle2nix-flake.url = "github:tadfisher/gradle2nix/v2";
    gradle-dot-nix.url = "github:CrazyChaoz/gradle-dot-nix";
  };
  outputs =
    inputs:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        android_sdk.accept_license = true;
      };

      myLib = pkgs.callPackage ./lib { inherit inputs; };
    in
    {
      packages.x86_64-linux = myLib.byNameOverlay ./apks;
      lib = myLib;
    };
}
