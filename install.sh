#!/usr/bin/env bash
# brizz-cli installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh -s -- --version v0.1.0
#   curl -fsSL https://raw.githubusercontent.com/brizzai/brizz-cli/master/install.sh | sh -s -- --dir /usr/local/bin

set -euo pipefail

REPO="brizzai/brizz-cli"
BIN_NAME="brizz"
INSTALL_DIR="${BRIZZ_INSTALL_DIR:-$HOME/.local/bin}"
VERSION=""

usage() {
    cat <<EOF
brizz-cli installer

Options:
  --version <tag>   Install a specific release (default: latest stable)
  --dir <path>      Install directory (default: \$HOME/.local/bin)
  -h, --help        Show this help

Environment:
  BRIZZ_INSTALL_DIR  Overrides --dir default
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --version) VERSION="$2"; shift 2 ;;
        --dir)     INSTALL_DIR="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
    esac
done

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Error: '$1' is required but not installed." >&2
        exit 1
    }
}

require curl
require tar
require uname
require mktemp
require shasum 2>/dev/null || require sha256sum

# Detect OS
OS_RAW=$(uname -s)
case "$OS_RAW" in
    Darwin)  OS="Darwin" ;;
    Linux)   OS="Linux" ;;
    MINGW*|MSYS*|CYGWIN*)
        echo "Error: Windows shell install is not supported. Download the zip from https://github.com/${REPO}/releases" >&2
        exit 1
        ;;
    *) echo "Error: Unsupported OS: $OS_RAW" >&2; exit 1 ;;
esac

# Detect arch (goreleaser archive name uses x86_64 for amd64, arm64 for arm64)
ARCH_RAW=$(uname -m)
case "$ARCH_RAW" in
    x86_64|amd64)  ARCH="x86_64" ;;
    arm64|aarch64) ARCH="arm64" ;;
    *) echo "Error: Unsupported architecture: $ARCH_RAW" >&2; exit 1 ;;
esac

echo "brizz-cli installer"
echo "Platform: ${OS}/${ARCH}"

# Resolve version: latest stable if not pinned
if [[ -z "$VERSION" ]]; then
    echo "Resolving latest release..."
    VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
        | head -n 1)
    if [[ -z "$VERSION" ]]; then
        echo "Error: Could not resolve latest release tag from GitHub API" >&2
        exit 1
    fi
fi

VERSION_NUM="${VERSION#v}"
VERSION_NUM="${VERSION_NUM#cli/v}"
echo "Version: ${VERSION} (${VERSION_NUM})"

ARCHIVE_NAME="brizz-cli_${VERSION_NUM}_${OS}_${ARCH}.tar.gz"
ARCHIVE_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARCHIVE_NAME}"
CHECKSUMS_URL="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading ${ARCHIVE_NAME}..."
curl -fsSL -o "$TMP_DIR/$ARCHIVE_NAME" "$ARCHIVE_URL" || {
    echo "Error: Download failed. Asset may not exist for this platform: ${ARCHIVE_URL}" >&2
    exit 1
}

echo "Verifying checksum..."
curl -fsSL -o "$TMP_DIR/checksums.txt" "$CHECKSUMS_URL" || {
    echo "Warning: Could not fetch checksums.txt; skipping verification." >&2
}

if [[ -f "$TMP_DIR/checksums.txt" ]]; then
    EXPECTED=$(grep " $ARCHIVE_NAME\$" "$TMP_DIR/checksums.txt" | awk '{print $1}')
    if [[ -z "$EXPECTED" ]]; then
        echo "Error: Checksum entry for $ARCHIVE_NAME not found in checksums.txt" >&2
        exit 1
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL=$(sha256sum "$TMP_DIR/$ARCHIVE_NAME" | awk '{print $1}')
    else
        ACTUAL=$(shasum -a 256 "$TMP_DIR/$ARCHIVE_NAME" | awk '{print $1}')
    fi
    if [[ "$EXPECTED" != "$ACTUAL" ]]; then
        echo "Error: Checksum mismatch. Expected $EXPECTED, got $ACTUAL" >&2
        exit 1
    fi
    echo "Checksum OK."
fi

echo "Extracting..."
tar -xzf "$TMP_DIR/$ARCHIVE_NAME" -C "$TMP_DIR"

mkdir -p "$INSTALL_DIR"
install -m 0755 "$TMP_DIR/$BIN_NAME" "$INSTALL_DIR/$BIN_NAME"

echo
echo "Installed $BIN_NAME ${VERSION} to $INSTALL_DIR/$BIN_NAME"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo
    echo "Note: $INSTALL_DIR is not in your PATH."
    echo "Add this to your shell config (~/.zshrc, ~/.bashrc, etc.):"
    echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo
echo "Get started:"
echo "  $BIN_NAME --version"
echo "  $BIN_NAME --help"
