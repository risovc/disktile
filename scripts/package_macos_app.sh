#!/bin/bash
# ==============================================================================
# package_macos_app.sh — Creates a Standalone DiskTile.app Bundle on macOS
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$ROOT_DIR/DiskTile"
OUTPUT_BUNDLE="$ROOT_DIR/DiskTile.app"

echo "========================================================"
echo "  Building Standalone DiskTile.app Bundle for macOS     "
echo "========================================================"

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "⚠️ This script is intended to be executed directly on macOS."
    echo "   Once you copy this folder to your Mac, run: ./scripts/package_macos_app.sh"
    exit 0
fi

cd "$APP_DIR"

echo "🔨 Compiling release binary with Swift..."
swift build -c release

BINARY_PATH=".build/release/DiskTile"

if [ ! -f "$BINARY_PATH" ]; then
    echo "❌ Build failed: binary not found at $BINARY_PATH"
    exit 1
fi

echo "📦 Creating macOS App Bundle directory structure..."
rm -rf "$OUTPUT_BUNDLE"
mkdir -p "$OUTPUT_BUNDLE/Contents/MacOS"
mkdir -p "$OUTPUT_BUNDLE/Contents/Resources"

# Copy binary
cp "$BINARY_PATH" "$OUTPUT_BUNDLE/Contents/MacOS/DiskTile"
chmod +x "$OUTPUT_BUNDLE/Contents/MacOS/DiskTile"

# Create Info.plist
cat << 'PLIST' > "$OUTPUT_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>DiskTile</string>
    <key>CFBundleIdentifier</key>
    <string>com.disktile.macstorage</string>
    <key>CFBundleName</key>
    <string>DiskTile</string>
    <key>CFBundleDisplayName</key>
    <string>DiskTile</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSSystemAdministrationUsageDescription</key>
    <string>DiskTile needs access to inspect disk storage and move selected items to Trash.</string>
</dict>
</plist>
PLIST

echo "✅ Successfully generated: $OUTPUT_BUNDLE"
echo "👉 You can now move DiskTile.app to /Applications or open it with: open '$OUTPUT_BUNDLE'"
