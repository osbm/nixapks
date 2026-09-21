# Updating an App

1. Bump `version`, the source `tag`/`rev`, and the fetch `hash` in the app's
   `package.nix` (get the new hash with
   `nix flake prefetch github:<owner>/<repo>/<tag>`).
2. Update `meta.android` if upstream changed minSdk/targetSdk/versionCode —
   the values live in the app's `gradle.properties`,
   `gradle/libs.versions.toml`, or `app/build.gradle.kts`.
3. Regenerate the app's verification metadata (see
   [Adding a New App](adding-new-app.md)) and merge it into the central
   lockfile:

   ```bash
   python3 lib/tools/merge-verification-metadata.py <app>/gradle/verification-metadata.xml
   ```

4. `nix build .#<app>.tests.meta` — builds the apk and verifies its manifest
   against `meta.android`.

## After `nix flake update`

Rebuild every app before committing a lock bump
(`nix build .#<app>.tests.meta`). Per-app `verification-metadata.xml` files
record the artifacts of the Gradle version they were generated with —
including Gradle's embedded Kotlin. When nixpkgs bumps `gradle_9`
(e.g. 9.5 → 9.7) the build asks for artifacts that are not in the metadata
(`Could not resolve org.jetbrains.kotlin:kotlin-stdlib:<new version>`).
The fix is to regenerate the metadata in the matching devshell; the diff is
usually a handful of lines.

## Hash conflicts in the lockfile

The merge tool refuses to change a hash that is already locked:

```
HASH CONFLICT com.github.tibbi:reprint (reprint-2cb206415d.jar)
  locked: 0c6de154...
  new:    201f65fa...
```

A published Maven artifact must never change bytes. A conflict means the
upstream repository rebuilt or replaced the artifact — JitPack does this
routinely, Maven Central and Google should never. Inspect before accepting
(`--force` keeps the new hash). Treat a conflict on a Central/Google
artifact as a potential supply-chain incident, not an inconvenience.
