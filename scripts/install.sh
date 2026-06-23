#!/usr/bin/env bash
set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
BIN_DIR="$PREFIX/bin"
BINARY="build/notes"

if [ ! -f "$BINARY" ]; then
    echo "error: '$BINARY' not found. Run 'make build' first." >&2
    exit 1
fi

mkdir -p "$BIN_DIR"
cp "$BINARY" "$BIN_DIR/notes"
echo "Installed notes to $BIN_DIR/notes"
