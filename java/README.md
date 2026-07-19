# nixjars

Build the Java/Maven dependency universe **from source**, in the Nix sandbox,
so that the APKs in this repository (and eventually anything JVM) can be built
without trusting a single binary jar from Maven Central, Google Maven, or
JitPack.

"Open source" on Maven Central means the license is open and source exists
somewhere. It does not mean the published jar was built from that source.
Nobody checks. nixjars is the long project of checking — and of replacing.

## Trust root

Everything here is built with, and only with:

- the nixpkgs JDK (OpenJDK, itself source-built in nixpkgs from a documented
  bootstrap chain)
- `buildMavenJar` (`lib/builders/build-maven-jar.nix`): plain `javac`, no
  Maven, no Gradle, no annotation processors

Every artifact carries a `passthru.provenance` tier:

| tier | meaning |
|------|---------|
| `from-source` | compiled here from pinned upstream VCS source |
| `rebuilt-verified` | binary consumed, but independently rebuilt and compared |
| `binary` | hash-pinned binary from an upstream repository (the enemy, to be eliminated) |

The trust root will grow before it shrinks (Kotlin compiler, Gradle seeds in
Phase 3) and that growth must stay explicit and documented.

## Phases

- **Phase 0 — the seam exists (now).** `buildMavenJar` + first six artifacts
  (javax.inject, jsr305, jetbrains-annotations, jspecify, slf4j-api, jsoup),
  all real dependencies of the apps in `apks/`, composed into a
  Maven-repository-layout `maven-repo` output.
- **Phase 1 — verification harness.** Compare every source-built jar against
  its Maven Central binary (normalized bytecode diff, non-blocking report).
  Findings are the product: "reproduces" raises trust in Central, "differs"
  is a discovery. Tooling to rank an app's lockfile by which artifacts to
  conquer next.
- **Phase 2 — real build systems, seeded.** Builders for ant-/maven-built
  libraries (commons-*, guava tier), multi-version support, correct dependency
  metadata in generated POMs, resource handling.
- **Phase 3 — the Kotlin/Gradle layer.** kotlinc-seeded builds of okio,
  kotlinx-*, okhttp; Gradle-built libraries offline; annotation processors
  (Room, Dagger). Seeds (Kotlin compiler, Gradle) enter the documented trust
  root here.
- **Phase 4 — substitution into apks/.** Overlay `maven-repo` over the binary
  offline repo in `buildGradleApk`; per-app metric: % of lockfile components
  served from source. Drive it up, app by app.
- **Phase 5 — shrink the seed.** Kotlin compiler bootstrap chain replay,
  Gradle archaeology, android.jar from AOSP. The horizon; Guix's Maven
  bootstrap is the only prior art at this depth.

Ongoing across all phases: weeding — flag jars that ship native blobs,
vendored/shaded copies of other libraries, or sources that cannot be located
at all.

## Usage

```
nix build .#javaPackages.jsoup     # one artifact, Maven-repo layout
nix build .#maven-repo             # all of them, composed into one repo
```

## Adding a package

Each package is `java/packages/<name>/package.nix` calling `buildMavenJar`
with pinned upstream VCS source (never a sources jar from Central — that is
still trusting the publisher). Prefer versions that appear in
`apks/*/*/verification-metadata.xml` so substitution (Phase 4) has targets.
