#!/usr/bin/env bash
#
# Builds and assembles a self-contained macOS NZ:P package from source.
# This currently builds FTEQW locally instead of consuming a release archive
# because the existing nightly packaging does not provide a macOS engine zip,
# and this script applies the local Retina mouse-coordinate patch before build.
#
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${BUILD_DIR:-"$ROOT_DIR/build/macos"}"
DOWNLOAD_DIR="$BUILD_DIR/downloads"
FTE_DIR="${FTE_DIR:-"$BUILD_DIR/fteqw"}"
PACKAGE_ROOT="$BUILD_DIR/package"
ARCH_NAME="$(uname -m)"
PACKAGE_DIR="$PACKAGE_ROOT/nzportable-macos-$ARCH_NAME"
OUT_DIR="$ROOT_DIR/out"
ENGINE_BIN="nzportable-sdl2"
BUILD_STRING="${BUILD_STRING:-"2.0.0-indev+$(date +'%Y%m%d%H%M%S')"}"

FTE_REPO="${FTE_REPO:-https://github.com/nzp-team/fteqw.git}"
FTE_REF="${FTE_REF:-master}"
ASSETS_URL="${ASSETS_URL:-https://github.com/nzp-team/assets/releases/download/newest/pc-nzp-assets.zip}"
QC_URL="${QC_URL:-https://github.com/nzp-team/quakec/releases/download/bleeding-edge/fte-nzp-qc.zip}"

if [ "$(uname -s)" != "Darwin" ]; then
    echo "This script builds the macOS package and must be run on macOS." >&2
    exit 1
fi

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1" >&2
        exit 1
    fi
}

require_pkg() {
    if ! pkg-config --exists "$1"; then
        echo "Missing pkg-config package: $1" >&2
        echo "Install dependencies with: brew install pkg-config sdl2 libpng jpeg-turbo opus libogg libvorbis gnutls" >&2
        exit 1
    fi
}

download() {
    local url="$1"
    local dest="$2"

    if [ -f "$dest" ]; then
        echo "Using cached $(basename "$dest")"
        return
    fi

    echo "Downloading $(basename "$dest")"
    curl -L --fail --retry 3 -o "$dest" "$url"
}

is_bundled_dylib() {
    case "$1" in
        /usr/lib/*|/System/Library/*|@executable_path/*|@loader_path/*|@rpath/*)
            return 1
            ;;
    esac

    [ -f "$1" ] && [ "${1##*.}" = "dylib" ]
}

list_dylib_deps() {
    otool -L "$1" | awk 'NR > 1 { print $1 }'
}

bundle_macos_dylibs() {
    local target="$1"
    local lib_dir="$2"
    local queue_file="$BUILD_DIR/dylib-queue.txt"
    local seen_file="$BUILD_DIR/dylib-seen.txt"
    local next_file="$BUILD_DIR/dylib-queue-next.txt"
    local dep
    local dep_name
    local dest
    local linked_file

    mkdir -p "$lib_dir"
    : > "$queue_file"
    : > "$seen_file"

    while IFS= read -r dep; do
        if is_bundled_dylib "$dep"; then
            printf '%s\n' "$dep" >> "$queue_file"
        fi
    done < <(list_dylib_deps "$target")

    while [ -s "$queue_file" ]; do
        dep="$(sed -n '1p' "$queue_file")"
        tail -n +2 "$queue_file" > "$next_file" || true
        mv "$next_file" "$queue_file"

        if grep -Fxq "$dep" "$seen_file"; then
            continue
        fi
        printf '%s\n' "$dep" >> "$seen_file"

        dep_name="$(basename "$dep")"
        dest="$lib_dir/$dep_name"
        if [ ! -f "$dest" ]; then
            cp -L "$dep" "$dest"
            chmod u+w "$dest"
        fi
        codesign --remove-signature "$dest" 2>/dev/null || true
        install_name_tool -id "@executable_path/lib/$dep_name" "$dest"

        while IFS= read -r dep; do
            if is_bundled_dylib "$dep" && ! grep -Fxq "$dep" "$seen_file"; then
                printf '%s\n' "$dep" >> "$queue_file"
            fi
        done < <(list_dylib_deps "$dest")
    done

    while IFS= read -r dep; do
        dep_name="$(basename "$dep")"
        install_name_tool -change "$dep" "@executable_path/lib/$dep_name" "$target"
        for linked_file in "$lib_dir"/*.dylib; do
            [ -e "$linked_file" ] || continue
            install_name_tool -change "$dep" "@executable_path/lib/$dep_name" "$linked_file" 2>/dev/null || true
        done
    done < "$seen_file"
}

sign_macos_package() {
    local target="$1"
    local lib_dir="$2"
    local linked_file

    for linked_file in "$lib_dir"/*.dylib; do
        [ -e "$linked_file" ] || continue
        codesign --force --sign - "$linked_file" >/dev/null
    done
    codesign --force --sign - "$target" >/dev/null
}

require_cmd brew
require_cmd cc
require_cmd codesign
require_cmd curl
require_cmd git
require_cmd install_name_tool
require_cmd make
require_cmd otool
require_cmd pkg-config
require_cmd sdl2-config
require_cmd unzip
require_cmd zip

require_pkg gnutls
require_pkg libpng
require_pkg ogg
require_pkg opus
require_pkg sdl2
require_pkg vorbis
require_pkg vorbisfile

BREW_PREFIX="$(brew --prefix)"
JPEG_PREFIX="$(brew --prefix jpeg-turbo 2>/dev/null || brew --prefix jpeg 2>/dev/null || true)"
if [ -z "$JPEG_PREFIX" ] || [ ! -f "$JPEG_PREFIX/include/jpeglib.h" ]; then
    echo "Missing JPEG headers. Install with: brew install jpeg-turbo" >&2
    exit 1
fi

PNG_LIB="$(pkg-config --variable=libdir libpng)/libpng.a"
JPEG_LIB="$JPEG_PREFIX/lib/libjpeg.a"
OPUS_LIB="$(pkg-config --variable=libdir opus)/libopus.a"
OGG_LIB="$(pkg-config --variable=libdir ogg)/libogg.a"
VORBIS_LIB="$(pkg-config --variable=libdir vorbis)/libvorbis.a"
VORBISFILE_LIB="$(pkg-config --variable=libdir vorbisfile)/libvorbisfile.a"

for lib in "$PNG_LIB" "$JPEG_LIB" "$OPUS_LIB" "$OGG_LIB" "$VORBIS_LIB" "$VORBISFILE_LIB"; do
    if [ ! -f "$lib" ]; then
        echo "Missing static library: $lib" >&2
        echo "Install dependencies with: brew install pkg-config sdl2 libpng jpeg-turbo opus libogg libvorbis gnutls" >&2
        exit 1
    fi
done

mkdir -p "$DOWNLOAD_DIR" "$OUT_DIR" "$PACKAGE_ROOT"

FTE_MOUSE_PATCH="$ROOT_DIR/patches/fteqw-macos-retina-mouse.patch"

if [ ! -d "$FTE_DIR/.git" ]; then
    echo "Cloning FTEQW into $FTE_DIR"
    git clone "$FTE_REPO" "$FTE_DIR"
fi

echo "Updating FTEQW to $FTE_REF"
git -C "$FTE_DIR" fetch --depth 1 origin "$FTE_REF"
git -C "$FTE_DIR" checkout --detach --force FETCH_HEAD

if git -C "$FTE_DIR" apply --check "$FTE_MOUSE_PATCH" >/dev/null 2>&1; then
    echo "Applying macOS Retina mouse-coordinate patch"
    git -C "$FTE_DIR" apply "$FTE_MOUSE_PATCH"
elif git -C "$FTE_DIR" apply --reverse --check "$FTE_MOUSE_PATCH" >/dev/null 2>&1; then
    echo "macOS Retina mouse-coordinate patch already applied"
else
    echo "Unable to apply $FTE_MOUSE_PATCH" >&2
    exit 1
fi

download "$ASSETS_URL" "$DOWNLOAD_DIR/pc-nzp-assets.zip"
download "$QC_URL" "$DOWNLOAD_DIR/fte-nzp-qc.zip"

ENGINE_DIR="$FTE_DIR/engine"
ENGINE_ARCH="$(cc -dumpmachine)"

echo "Fetching Vulkan headers for $ENGINE_ARCH"
mkdir -p "$ENGINE_DIR/libs-$ENGINE_ARCH"
make -C "$ENGINE_DIR" "libs-$ENGINE_ARCH/vulkan/vulkan.h" PKGCONFIG=pkg-config

BASE_CFLAGS="-Wall -Wno-pointer-sign -Wno-unknown-pragmas -Wno-format-zero-length -Wno-strict-aliasing"
BASE_CFLAGS="$BASE_CFLAGS -Iclient -Iserver -Icommon -Igl -Id3d -Iqclib -I. -I./dxsdk9/include -I./dxsdk7/include"
BASE_CFLAGS="$BASE_CFLAGS -I$BREW_PREFIX/include -I$BREW_PREFIX/include/opus -I$(pkg-config --variable=includedir libpng) -I$JPEG_PREFIX/include"
BASE_CFLAGS="$BASE_CFLAGS -DLIBJPEG_STATIC -DLIBPNG_STATIC -DOPUS_STATIC -DGNUTLS_STATIC -DFREETYPE_STATIC -DLIBVORBISFILE_STATIC"

echo "Building macOS engine"
make -C "$ENGINE_DIR" clean FTE_TARGET=SDL2 FTE_CONFIG=nzportable PKGCONFIG=pkg-config
make -C "$ENGINE_DIR" m-rel \
    FTE_TARGET=SDL2 \
    FTE_CONFIG=nzportable \
    PKGCONFIG=pkg-config \
    STRIPFLAGS= \
    BASE_CFLAGS="$BASE_CFLAGS" \
    IMAGELDFLAGS="$PNG_LIB $JPEG_LIB" \
    OGGVORBISLDFLAGS="$VORBISFILE_LIB $VORBIS_LIB $OGG_LIB" \
    LIBOPUS_LDFLAGS="$OPUS_LIB" \
    COMMONLDDEPS="$(pkg-config --libs gnutls)" \
    LIBSPEEX_STATIC= \
    LIBSPEEX_LDFLAGS= \
    -j"$(sysctl -n hw.ncpu)"

if [ ! -x "$ENGINE_DIR/release/$ENGINE_BIN" ]; then
    echo "Expected engine binary not found: $ENGINE_DIR/release/$ENGINE_BIN" >&2
    exit 1
fi

echo "Assembling package"
chmod -R u+w "$PACKAGE_ROOT" 2>/dev/null || true
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR/nzp"
unzip -q "$DOWNLOAD_DIR/pc-nzp-assets.zip" -d "$PACKAGE_DIR"
unzip -q "$DOWNLOAD_DIR/fte-nzp-qc.zip" -d "$PACKAGE_DIR/nzp"
cp "$ENGINE_DIR/release/$ENGINE_BIN" "$PACKAGE_DIR/$ENGINE_BIN"
chmod +x "$PACKAGE_DIR/$ENGINE_BIN"
echo "Bundling Homebrew dynamic libraries"
bundle_macos_dylibs "$PACKAGE_DIR/$ENGINE_BIN" "$PACKAGE_DIR/lib"
echo "Signing bundled macOS binaries"
sign_macos_package "$PACKAGE_DIR/$ENGINE_BIN" "$PACKAGE_DIR/lib"
printf '%s\n' "$BUILD_STRING" > "$PACKAGE_DIR/nzp/version.txt"
touch "$PACKAGE_DIR/config.cfg" "$PACKAGE_DIR/user_settings.cfg" "$PACKAGE_DIR/autoexec.cfg"
touch "$PACKAGE_DIR/nzp/config.cfg" "$PACKAGE_DIR/nzp/user_settings.cfg" "$PACKAGE_DIR/nzp/autoexec.cfg"

cat > "$PACKAGE_DIR/Run NZPortable.command" <<'LAUNCHER'
#!/usr/bin/env bash
set -euo pipefail
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$APP_DIR"
exec ./nzportable-sdl2 "$@"
LAUNCHER
chmod +x "$PACKAGE_DIR/Run NZPortable.command"

SMOKE_LOG="$BUILD_DIR/smoke.log"
echo "Running package smoke test"
(
    cd "$PACKAGE_DIR"
    "./$ENGINE_BIN" +quit > "$SMOKE_LOG" 2>&1
)

if grep -E "couldn't exec|fte\\.cfg|GnuTLS .*not available|no tls provider" "$SMOKE_LOG" >/dev/null; then
    echo "Smoke test found a startup problem:" >&2
    grep -E "couldn't exec|fte\\.cfg|GnuTLS .*not available|no tls provider" "$SMOKE_LOG" >&2
    exit 1
fi
rm -f "$PACKAGE_DIR/conhistory.txt"

ZIP_PATH="$OUT_DIR/nzportable-macos-$ARCH_NAME.zip"
echo "Writing $ZIP_PATH"
rm -f "$ZIP_PATH"
(
    cd "$PACKAGE_ROOT"
    zip -q -r "$ZIP_PATH" "$(basename "$PACKAGE_DIR")"
)

echo "Build complete."
echo "Package directory: $PACKAGE_DIR"
echo "Archive: $ZIP_PATH"
echo "Run with: \"$PACKAGE_DIR/Run NZPortable.command\""
