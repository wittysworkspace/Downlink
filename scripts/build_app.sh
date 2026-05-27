#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/Downlink.app"
EXECUTABLE_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
VENDOR_BIN_DIR="$ROOT_DIR/Vendor/bin"
ICON_FILE="$ROOT_DIR/Assets/AppIcon.icns"

cd "$ROOT_DIR"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$EXECUTABLE_DIR" "$RESOURCES_DIR"
cp ".build/release/Downlink" "$EXECUTABLE_DIR/Downlink"

if [ -f "$ICON_FILE" ]; then
    cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -d "$VENDOR_BIN_DIR" ]; then
    mkdir -p "$RESOURCES_DIR/bin"
    find "$VENDOR_BIN_DIR" -maxdepth 1 -type f ! -name ".gitkeep" -exec cp {} "$RESOURCES_DIR/bin/" \;
    chmod +x "$RESOURCES_DIR/bin/"* 2>/dev/null || true
fi

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "https://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Downlink</string>
    <key>CFBundleIdentifier</key>
    <string>local.downlink.app</string>
    <key>CFBundleName</key>
    <string>Downlink</string>
    <key>CFBundleDisplayName</key>
    <string>Downlink</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "Built $APP_DIR"
