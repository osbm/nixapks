{
  description = "Build android applications with nix";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  outputs = { self, nixpkgs }:
  let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    callPackage = pkgs.callPackage;
    stdenv = pkgs.stdenv;
  in
  {
    packages.x86_64-linux.lichess = callPackage ./apks/li/lichess/package.nix { };
    packages.x86_64-linux.default = self.packages.x86_64-linux.lichess;
  };
}
