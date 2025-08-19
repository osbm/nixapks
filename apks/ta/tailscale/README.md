# Tailscale Android APK

This package builds the Tailscale Android application from source.

## Status

🚧 **Work in Progress** - Package structure created but needs completion:

### TODO:
1. **Update version**: Check [Tailscale Android releases](https://github.com/tailscale/tailscale-android/releases) for the latest version
2. **Update hash**: Run `nix-prefetch-url --unpack https://github.com/tailscale/tailscale-android/archive/v{VERSION}.tar.gz` to get the correct hash
3. **Generate dependencies**: Run `nix build .#tailscale.mitmCache.updateScript` to generate deps.json
4. **Verify build output**: Check if the APK output path is correct (might be `app-universal-release-unsigned.apk`)
5. **Test build**: Run `nix build .#tailscale` to verify it builds successfully

### Quick Setup:
Run `./update-tailscale.sh` from the repository root to automatically update version and hash.

## About Tailscale

Tailscale is a VPN service that makes the devices and applications you own accessible anywhere in the world, securely and effortlessly. It enables encrypted point-to-point connections using the open source WireGuard protocol.

- **Repository**: https://github.com/tailscale/tailscale-android
- **License**: BSD-3-Clause
- **Build System**: Gradle