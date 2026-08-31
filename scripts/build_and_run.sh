#!/bin/bash
# ==============================================================================
# build_and_run.sh — Build and Launch DiskTile on macOS
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/DiskTile"

echo "========================================================"
echo "  DiskTile — Mac Storage Visualizer Build & Launcher   "
echo "========================================================"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️  Note: You are currently running on $(uname -s)."
    echo "   The Swift/SwiftUI binary requires macOS to execute natively."
    echo "   To test immediately on this machine, launch the live preview:"
    echo "   $ python3 $ROOT_DIR/preview_app/server.py"
    echo "========================================================"
    exit 0
fi

cd "$APP_DIR"

echo "📦 Building DiskTile with Swift Package Manager..."
swift build -c release

echo "🚀 Launching DiskTile..."
.build/release/DiskTile
