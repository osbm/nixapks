#!/usr/bin/env bash
# Helper script to update Tailscale package with latest version and hash

set -e

echo "Fetching latest Tailscale Android release..."

# Get latest release from GitHub API
LATEST_RELEASE=$(curl -s https://api.github.com/repos/tailscale/tailscale-android/releases/latest)
LATEST_VERSION=$(echo "$LATEST_RELEASE" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
    echo "Could not fetch latest version. Please check manually at:"
    echo "https://github.com/tailscale/tailscale-android/releases"
    exit 1
fi

echo "Latest version: $LATEST_VERSION"

# Get the hash for the source
echo "Fetching source hash..."
HASH=$(nix-prefetch-url --unpack "https://github.com/tailscale/tailscale-android/archive/v${LATEST_VERSION}.tar.gz")

if [ -z "$HASH" ]; then
    echo "Could not fetch source hash."
    exit 1
fi

echo "Hash: $HASH"

# Update package.nix
sed -i "s/version = \"[^\"]*\"/version = \"$LATEST_VERSION\"/" apks/ta/tailscale/package.nix
sed -i "s/hash = \"[^\"]*\"/hash = \"sha256-$HASH\"/" apks/ta/tailscale/package.nix

echo "Updated package.nix with version $LATEST_VERSION and hash $HASH"
echo "Now run: nix build .#tailscale"