{
  lib,
  stdenv,
  pkgs
}:

stdenv.mkDerivation rec {
  name = "lichess";
  version = "0.14.14";
  src = pkgs.fetchFromGitHub {
    owner = "lichess-org";
    repo = "mobile";
    tag = "v${version}";
    hash = "sha256-NqS3vyz9x2yILTuJxvnSz4F8ZpZ7NUf/+jVmxsqPWpk=";
  };


  nativeBuildInputs = [
    pkgs.yarn
  ];
  buildInputs = [
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
