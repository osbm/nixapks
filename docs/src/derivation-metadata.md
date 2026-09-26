

# Derivation Metadata

A derivation's metadata gives information regarding the application and its target android environment.

An example of a proper metadata field for an android application is as follows:

```nix
meta = {
  description = "An open source flashcard app for spaced repetition learning";
  homepage = "https://mihon.app";
  license = lib.licenses.asl20;
  maintainers = with lib.maintainers; [ osbm ]; # from nixpkgs maintainers list
  android = {
    minSdk = 26;
    targetSdk = 36;
    applicationId = "app.mihon";
    abis = [
      "armeabi-v7a"
      "arm64-v8a"
      "x86"
      "x86_64"
    ];
  };
};
```

## Description

A short description of the application.

## Homepage

The homepage URL of the application. If it does not have a homepage, you can use the repository URL.

## License

The license under which the application is distributed. You can use licenses from `lib.licenses` in nixpkgs.

## Maintainers

A list of maintainers for the derivation. You can use maintainers from `lib.maintainers` in nixpkgs.

TODO: what happens if the maintainer is not in the nixpkgs maintainers list?

## Android

Metadata specific to the Android application, including SDK versions, application ID, and supported ABIs.

### minSdk

The minimum SDK version required to run the application.

### targetSdk

The target SDK version for which the application is optimized.

### applicationId

The unique application ID (package name) for the Android application.

### abis

A list of supported ABIs (Application Binary Interfaces) for the application. Common values include:
- `armeabi-v7a`
- `arm64-v8a`
- `x86`
- `x86_64`


## No runtime dependencies

An APK is a self-contained file: it must not reference any Nix store path.
This is not a convention but a build-time guarantee. Every package under
`apks/` is given `allowedReferences = [ ]` (in `lib/default.nix`; the
gradle2nix builder sets it itself), so Nix refuses to register an output
that refers to the store:

```
error: output '/nix/store/…-fossify-calculator-1.4.0.apk' is not allowed to refer to the following paths:
```

Nothing has to be added to a package for this, and there is no separate CI
step: any `nix build` of an app, locally or in CI, is the check. If it ever
triggers, look for a store path leaking into the apk (a hard-coded tool path
in a generated file, a copied symlink, ...). Avoid `buildInputs` in APK
packages — evaluation warns about them — and put tools in
`nativeBuildInputs`.
