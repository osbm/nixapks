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
    pkgs.androidenv
    pkgs.androidsdk
    pkgs.androidndk
    pkgs.nodejs-18_x
    pkgs.yarn
  ];
  buildInputs = [
    pkgs.androidenv
    pkgs.androidsdk
    pkgs.androidndk
    pkgs.nodejs-18_x
    pkgs.yarn
  ];

  buildPhase = ''
    export ANDROID_HOME=${pkgs.androidsdk}/libexec
    export ANDROID_NDK_HOME=${pkgs.androidndk}/libexec
    export PATH=$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools:$PATH

    yarn install
    yarn android:build

    # The APK is built in the android/app/build/outputs/apk/debug directory


  '';

  installPhase = ''
    mkdir -p $out
    cp -r android/app/build/outputs/apk/debug/app-debug.apk $out/lichess.apk

  '';

  meta = with lib; {
    description = "Lichess mobile app";
  };

}
