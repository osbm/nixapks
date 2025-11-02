

# Analyzing an APK File

First build the app

```sh
nix build .#mihon
```

Then use `apktool` to decode the APK file

```sh
nix run nixpkgs#apktool -- d result
```