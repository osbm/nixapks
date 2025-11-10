

# ROADMAP

The thing is, I am a very shitty developer. And my capabilities are extremely limited. But I am ambitious so nix is perfect for me 😭.

- [x] Add CI that builds all apps on every commit.
- [x] Design a proper meta field for the needs of android apps.
    - [x] description
    - [x] license
    - [x] main page
    - [x] maintainers
    - [x] minSdkVersion (explain what is this)
    - [x] targetSdkVersion (explain what is this)
    - [x] abi (list of supported abis: armeabi-v7a, arm64-v8a, x86, x86_64)
    - [x] applicationID (the unique identifier of the app, e.g. com.example.app)
- [x] Check the meta field
- [x] Add documentation on github pages.
- [ ] Add first flutter app.
- [ ] Add first react-native app.
- [ ] Add first ionic app.
- [ ] Support building apps on more platforms (currently only x86_64-linux is supported)
- [ ] After adding 10 different apps (they all must be successfully built) ask to migrate this repo to the nix-community github organization.
- [ ] Have base functional coverage [See functional-coverage](functional-coverage.md)
- [ ] Check if the apk can be installed (hopefully on multiple architectures)
- [ ] Check if the output derivation has any runtime dependencies (it should not)
- [ ] Check if the app got an update (maybe from fdroid or github releases) and create a PR automatically.
- [ ] Add binary cache
- [ ] Prepare reproducibility report
- [ ] Compile an application without using any maven repository (fetch all dependencies from their respective sources and compile them into jar files and feed the resulting jars to the apk build process) (this is probably impossible but worth a try)