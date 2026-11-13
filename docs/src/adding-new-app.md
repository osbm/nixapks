# Adding new applications to NixApks

To add a new application to nixapks, you need a derivation that outputs an
apk file. For Gradle apps (plain Java/Kotlin Android projects) the repository
provides `buildGradleApk` and a central dependency lockfile, so a new app is
usually ~50 declarative lines.

## Gradle-based Android apps

Gradle can't download dependencies inside the Nix sandbox, so dependency
hashes must be collected up front. All hashes live in one central lockfile,
`lib/maven-lock.json`, shared by every app — you only add the entries your
app introduces.

### 1. Generate the app's verification metadata

Clone the app at the release tag and run, inside the
`generate-gradle-metadata` devshell (`nix develop .#generate-gradle-metadata`):

```bash
gradle -M sha256 <releaseTask> \
  -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/<version>/aapt2
```

where `<releaseTask>` is the task that assembles the release apk (find it
with `./gradlew tasks --all | grep assemble`, e.g. `assembleFossRelease`).
This writes `gradle/verification-metadata.xml` in the app's source tree.

Apps on Android Gradle Plugin 9 need Gradle 9 (check
`gradle/wrapper/gradle-wrapper.properties`): use the
`generate-gradle-metadata-gradle9` devshell instead and set
`gradle = pkgs.gradle_9;` in the package. Always generate the metadata with
the same Gradle major the package builds with.

### 2. Merge it into the central lockfile

```bash
python3 lib/tools/merge-verification-metadata.py <app>/gradle/verification-metadata.xml
```

Entries already known are deduplicated. If an already-locked artifact
reports a *different* hash, the merge fails on purpose — see
[Updating an App](updating-an-app.md).

### 3. Write the package

Create `apks/<first-two-letters>/<app-name>/package.nix` calling
`lib.buildGradleApk` — see `apks/fo/fossify-clock/package.nix` for a
template. Do not pass `verificationMetadata`; the builder generates it from
the central lockfile. A complete `meta` (including `meta.android` with
`minSdk`, `targetSdk`, `applicationId`, `abis`) is required — evaluation
fails without it.

### 4. Build and verify

```bash
nix build .#<app-name>.tests.meta
```

This builds the apk and then checks it against `meta.android` using
`aapt2 dump badging`. CI runs the same check for every app.

### gradle2nix way (`buildGradleApkGradle2Nix`)

Repository: https://github.com/tadfisher/gradle2nix

Generate a per-app `gradle.lock` by running the gradle2nix CLI against the
app source (inside the `generate-gradle-metadata` devshell so the Android
SDK is available):

```bash
nix run github:tadfisher/gradle2nix -- -t <releaseTask> --gradle-jdk "$JDK_HOME" \
  -- -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/<version>/aapt2
```

Commit the resulting `gradle.lock` next to `package.nix` and call
`lib.buildGradleApkGradle2Nix` with `lockFile = ./gradle.lock;` — see
`apks/fo/fossify-thankyou/package.nix`. Unlike the verification-metadata
methods, the lock records full artifact URLs alongside hashes.

> This repo deliberately keeps several builder methods alive to compare
> them (ease of adding/updating apps, breakage rate, readability). The
> builder name in each package.nix identifies the method:
> `buildGradleApkGradleDotNix` (per-app verification-metadata.xml),
> `buildGradleApkCentralizedLock` (shared lib/maven-lock.json),
> `buildGradleApkGradle2Nix` (per-app gradle.lock).

## React Native apps

There is no builder yet, only one worked example:
`apks/bl/bluesky/package.nix` (an Expo app, React Native and Hermes built
from source). It is a single offline derivation that runs, in order:

1. `pnpm install` from `pkgs.fetchPnpmDeps` (via `pnpmConfigHook`; pnpm 11
   needs `fetcherVersion = 4`).
2. Any code generation upstream runs in `postinstall` (install scripts are
   skipped), e.g. `lingui compile`.
3. `expo prebuild --platform android --no-install` — works offline, the
   template comes from `node_modules`.
4. `gradle :app:assembleRelease --offline` with a gradle-dot-nix init script,
   exactly like the Gradle apps above.

Things that differ from a plain Gradle app:

- Generate `verification-metadata.xml` from the *prebuilt* tree (after
  steps 1-3), running `gradle -M sha256 :app:assembleRelease` inside
  `android/`. The Android SDK needs the NDK and usually two CMake versions
  (ReactAndroid wants 3.30.5, third-party libraries 3.22.1).
- ReactAndroid downloads source tarballs (boost, folly, glog, fmt,
  double-conversion, fast_float, hermes). Fetch them with `fetchurl` and
  point `REACT_NATIVE_DOWNLOADS_DIR` at a directory holding them under the
  exact file names ReactAndroid expects.
- Expo modules ship prebuilt AARs in `node_modules/*/local-maven-repo`.
  They appear in the metadata but cannot be downloaded: copy those
  directories into a derivation and pass it as gradle-dot-nix's
  `local-maven-repos`.
- Set `LANG`/`LC_ALL` to `C.UTF-8`, otherwise Gradle cannot unpack boost
  (`MalformedInputException`).
- Expect a slow cold build: bluesky has ~3900 maven artifacts, which
  gradle-dot-nix turns into ~7900 tiny derivations (1.5-2 h of fetching
  before a ~9 min compile). Warm rebuilds only pay for the compile.

## Flutter apps (`buildFlutterApk`)

Worked example: `apks/wg/wger/package.nix`. A Flutter app has two dependency
worlds and therefore two lock files next to `package.nix`:

- `pubspec.lock.json` — the app's `pubspec.lock` converted with
  `yq . pubspec.lock > pubspec.lock.json`. nixpkgs' pub2nix machinery turns
  it into one fixed-output derivation per Dart package. Git-sourced pub
  dependencies have no hash in the lock: prefetch each one
  (`nix-prefetch-git --url <url> --rev <resolved-ref>`) and pass it in
  `gitHashes = { <package> = "sha256-..."; }`.
- `verification-metadata.xml` — the Gradle side, consumed by gradle-dot-nix
  exactly like the Gradle apps. The Flutter engine (`io.flutter:*`) is just
  another Maven repository, `https://storage.googleapis.com/download.flutter.io`,
  already in the builder's default `mavenRepos`.

The builder does not let `flutter build apk` run Gradle: that goes through
the Gradle wrapper, which downloads a distribution. Instead it runs
`flutter build apk --release --config-only`, which prepares everything the
real command would (`android/local.properties`, the release-mode
`GeneratedPluginRegistrant.java`, migrations) and stops, and then runs
Gradle itself on `android/` (`gradle -p android :app:assembleRelease --offline`).
The Flutter Gradle plugin shells out to `flutter assemble` for the Dart
compile. The pub step inside `flutter build` is skipped automatically
because pub2nix marks `package_config.json` as third-party generated.

### Generating `verification-metadata.xml`

Clone the app at its tag and, with the same Flutter the package uses
(`nix shell nixpkgs#flutter344`) and an Android SDK with the pieces listed
in `androidSdkPackages`, run:

```bash
flutter pub get
flutter build apk --release --config-only
# point flutter.sdk at a *writable* copy of the SDK, see below
lndir -silent "$FLUTTER_ROOT" /tmp/flutter-sdk
sed -i 's|^flutter.sdk=.*|flutter.sdk=/tmp/flutter-sdk|' android/local.properties
gradle -p android -M sha256 :app:assembleRelease \
  -I lib/builders/flutter-init.gradle \
  -Dorg.gradle.project.android.aapt2FromMavenOverride=$ANDROID_HOME/build-tools/<version>/aapt2
```

with Gradle 8 (see below). The result is
`android/gradle/verification-metadata.xml`. Making the pub cache read-only
(`chmod -R a-w $PUB_CACHE`) before the Gradle run reproduces the sandbox
faithfully: every plugin that tries to write into its own directory fails
here first.

### Things that differ from a plain Gradle app

- **Writable Flutter SDK.** The Flutter Gradle plugin is a Gradle included
  build (`includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")`)
  and writes its own build output next to its sources. The builder gives
  Gradle an `lndir` copy of the SDK in `$TMPDIR` instead of the store path.
- **Gradle 8, not 9.** Every Flutter plugin becomes a Gradle subproject
  whose directory is the pub package — a read-only store path in the
  sandbox. Gradle 9 refuses to configure projects in read-only directories
  (`Configuring project ':x' without an existing directory is not allowed`);
  Gradle 8.14 only warns. Use `pkgs.gradle_8` (the default) even if the
  upstream wrapper pins 9.
- **Native plugins.** AGP stages CMake/ndk-build output in
  `<plugin>/.cxx`, read-only in the sandbox; `lib/builders/flutter-init.gradle`
  (always passed by the builder) moves it under the root build directory.
  Each native plugin also pins its own `ndkVersion` and AGP insists on that
  exact one: list every NDK the plugins ask for in `androidSdkPackages`
  (`grep -rh ndkVersion $PUB_CACHE/hosted/pub.dev/*/android/build.gradle`),
  likewise every `compileSdk` level (`platforms-android-*`) and the AGP
  default build-tools (35.0.0 for AGP 8.13).
- **Build hooks that download.** Some Dart packages (sqlite3, powersync)
  have a `hook/build.dart` that downloads a prebuilt native library per ABI
  from GitHub releases during the Dart compile, inside Gradle. They cache
  the file under `.dart_tool/hooks_runner/shared/<package>/build/download-<8
  hex of its sha256>/` and reuse it when the hash matches, so the builder
  pre-seeds that cache from `fetchurl` via `hookDownloads` (hashes come
  from the package source, e.g. `lib/src/hook/asset_hashes.dart`). Find
  them with `ls $PUB_CACHE/hosted/pub.dev/*/hook` and, after an impure
  build, `ls .dart_tool/hooks_runner/shared/*/build/download-*`.
- **Dev-only plugins.** `integration_test` and friends are excluded from
  release builds by the Flutter Gradle plugin. The registrant must agree,
  which is why the builder runs `flutter build --config-only` *without*
  `--no-pub` (`--no-pub` also skips regenerating the registrant).
- **Signing.** Upstream release configs usually read a keystore from a file
  that only their CI has. Patch `signingConfig signingConfigs.release` to
  `signingConfigs.debug` in `postPatch` until the signing mechanism from the
  roadmap exists.
- **Flutter version.** Use the nixpkgs `flutterXYZ` matching the minor
  upstream's CI pins (`.github/`); `pubspec.lock`'s `sdks:` section gives
  the lower bound.
