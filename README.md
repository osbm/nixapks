
# Nixapks

A repository of derivations that builds as much open source android applications as possible.


## Directories

## Roadmap

- Write custom derivation to compile Gradle based applications.
- Add flutter apps
- When there is enough apps, ask to get this repository be added to the nix-community organization.
- Add documentation
- Check reproducibility

### Why though? Why not just use google play or even f-droid?

I love nix and being able to build my packages and even my operating system in a pure and reproducible way is awesome. I want that for my android devices. But i find the state of development in the android worse than python 😭🙏.

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