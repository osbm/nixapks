{
  lib,
  stdenv,
  pkgs
}:

stdenv.mkDerivation rec {
  name = "wireguard";
  version = "1.0.20231018";
  src = pkgs.fetchzip {
    url = "https://git.zx2c4.com/wireguard-android/snapshot/wireguard-android-${version}.tar.xz";
    sha256 = "sha256-09bXYljoXvwHn3QkzBjQHsIbvXrCzBceUSXVRRc8q8g=";
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
