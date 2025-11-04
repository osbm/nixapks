
# Nixapks

A repository of derivations that builds as much open source android applications as possible.

```
$ nix build --print-out-paths github:osbm/nixapks#smouldering_durtles
/nix/store/z796iq87azckb8nsajpv43g7ybadq47s-smouldering_durtles-1.2.3.apk
```



# Notes

Successful nix apk builds:
- https://github.com/CrazyChaoz/Minimal-Android-UWB-App
- https://github.com/iyox-studios/iyox-Wormhole
- https://github.com/expenses/irohdroid
- https://github.com/nix-community/robotnix/tree/master/apks/chromium
- https://github.com/nix-community/robotnix/tree/463c3f66062a999cf339bc752501ae5906582df7/apks/fdroid
- https://github.com/SpiralP/mobile_nebula


Important tools:
- https://github.com/CrazyChaoz/gradle-dot-nix : This flake can generate the full maven repo required to build a gradle app from gradle/verification-metadata.xml, all in the sandbox, without code generation.
- https://github.com/tadfisher/gradle2nix :  Generate Nix expressions which build Gradle-based projects.
- https://github.com/tadfisher/android-nixpkgs : All packages from the Android SDK repository, packaged with Nix.
- gradle.fetchDeps : A tool to fetch Gradle dependencies and generate a Nix expression for them. This is used in nixpks to fetch the dependencies of the Gradle build system and generate deps.json files.


# License

All the nix derivations in this repository are licensed under the MIT license. See the LICENSE file for details.

This license does not apply to the android applications built using these derivations. Please refer to the respective application's source code repository for licensing information.