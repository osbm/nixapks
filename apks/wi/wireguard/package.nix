{
  lib,
  stdenv,
  pkgs
}:

stdenv.mkDerivation rec {
  name = "wireguard";
  version = "1.0.20231018";
  src = pkgs.fetchgit {
    url = "https://git.zx2c4.com/wireguard-android";
    tag = "v${version}";
    hash = "";
  };


  nativeBuildInputs = [
    pkgs.yarn
  ];
  buildInputs = [
    pkgs.yarn
  ];

  buildPhase = ''
    cd $src
    ./gradlew assembleRelease
  '';

  installPhase = ''
    cp -r android/app/build/outputs/apk/debug/app-debug.apk $out/lichess.apk

  '';

  meta = with lib; {
    description = "Lichess mobile app";
  };

}
