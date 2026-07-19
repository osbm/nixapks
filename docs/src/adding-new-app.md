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

### gradle2nix way

Repository: https://github.com/tadfisher/gradle2nix

TODO: Write this section.

## React Native apps

Not yet supported.

## Flutter apps

Not yet supported.
