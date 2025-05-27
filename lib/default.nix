{ pkgs, ... }:
{
  by-name-overlay =
    baseDirectory:
    let
      namesForShard =
        shard: _:
        pkgs.lib.mapAttrs (name: _: baseDirectory + "/${shard}/${name}/package.nix") (
          builtins.readDir (baseDirectory + "/${shard}")
        );
      packageFiles = pkgs.lib.mergeAttrsList (
        pkgs.lib.attrsets.mapAttrsToList namesForShard (builtins.readDir baseDirectory)
      );
    in
    pkgs.lib.mapAttrs (name: _: pkgs.callPackage _ { }) packageFiles;
}
