#!/bin/bash
set -euo pipefail

# Get architecture
ARCH="$1"

# Set archive URL per arch
case "$ARCH" in
    x86_64)
        ARCHIVE_URL="https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-linux64.zip"
        ;;
    aarch64)
        ARCHIVE_URL="https://github.com/nzp-team/nzportable/releases/download/nightly/nzportable-linuxarm64.zip"
        ;;
    *)
        echo "Unsupported arch: $ARCH" && exit 1
        ;;
esac

# Get build version
wget -q https://github.com/nzp-team/nzportable/releases/download/nightly/build-version.txt
BUILD_VERSION=$(cat build-version.txt)

# Download the archive
wget -q "$ARCHIVE_URL" -O nzportable.zip

# Get sha256
ARCHIVE_SHA=$(sha256sum nzportable.zip | cut -d' ' -f1)

# Replace placeholders in manifest
sed -i "s/ARCHIVE_SHA256_REPLACE/${ARCHIVE_SHA}/" gay.nzp.nzportable.json
sed -i "s/\"nightly\"/\"${BUILD_VERSION}\"/" gay.nzp.nzportable.json

# Output the updated manifest
cat gay.nzp.nzportable.json