{
  pkgs,
  lib,
  ...
}:
{
  # Verify a built APK against its declared meta.android by parsing
  # `aapt2 dump badging` output — the same manifest parse the device's
  # package manager performs at install time.
  #
  # This is a separate, cheap derivation (exposed as passthru.tests.meta)
  # rather than a check inside the app build, so editing metadata re-runs a
  # seconds-long check instead of a full Gradle build.
  verifyApkMeta =
    {
      # derivation whose $out is the APK file
      apk,
      # android-nixpkgs sdk derivation to take aapt2 from; pass the same one
      # the app was built with so the check adds nothing new to the closure
      sdk,
      android ? apk.meta.android,
      # expected versionName; null disables the check
      version ? apk.version or null,
    }:
    let
      # An APK with no native libraries runs on any ABI; by convention such
      # universal APKs are declared with all four standard ABIs.
      allAbis = "arm64-v8a armeabi-v7a x86 x86_64";
      expectedAbis = lib.concatStringsSep " " (lib.naturalSort (android.abis or [ ]));
    in
    pkgs.runCommand "verify-meta-${apk.name}" { } ''
      aapt2=$(ls ${sdk}/share/android-sdk/build-tools/*/aapt2 | head -n 1)
      "$aapt2" dump badging ${apk} > badging.txt

      get() { sed -n "$1" badging.txt | head -n 1; }
      actual_package=$(get "s/^package: name='\([^']*\)'.*/\1/p")
      actual_vname=$(get "s/.*versionName='\([^']*\)'.*/\1/p")
      actual_vcode=$(get "s/.*versionCode='\([^']*\)'.*/\1/p")
      actual_minsdk=$(get "s/^sdkVersion:'\([^']*\)'.*/\1/p")
      actual_targetsdk=$(get "s/^targetSdkVersion:'\([^']*\)'.*/\1/p")
      actual_abis=$(sed -n "s/^native-code: //p" badging.txt | tr -d "'" | tr ' ' '\n' | sort | xargs)
      test -n "$actual_abis" || actual_abis="universal"

      fail=0
      check() {
        if [ "$2" != "$3" ]; then
          echo "MISMATCH $1: meta declares '$2' but the apk says '$3'" | tee -a $out
          fail=1
        else
          echo "ok $1: $3" >> $out
        fi
      }

      touch $out
      ${lib.optionalString (android ? applicationId) ''
        check applicationId "${android.applicationId}" "$actual_package"
      ''}
      ${lib.optionalString (android ? minSdk) ''
        check minSdk "${toString android.minSdk}" "$actual_minsdk"
      ''}
      ${lib.optionalString (android ? targetSdk) ''
        check targetSdk "${toString android.targetSdk}" "$actual_targetsdk"
      ''}
      ${lib.optionalString (android ? versionCode) ''
        check versionCode "${toString android.versionCode}" "$actual_vcode"
      ''}
      ${lib.optionalString (version != null) ''
        check versionName "${version}" "$actual_vname"
      ''}
      ${lib.optionalString (expectedAbis != "") ''
        if [ "$actual_abis" = "universal" ] && [ "${expectedAbis}" = "${allAbis}" ]; then
          echo "ok abis: universal apk (no native code), declared as all standard ABIs" >> $out
        else
          check abis "${expectedAbis}" "$actual_abis"
        fi
      ''}

      if [ "$fail" != 0 ]; then
        echo "APK does not match its meta.android declaration:"
        cat badging.txt | head -n 5
        exit 1
      fi
      cat $out
    '';
}
