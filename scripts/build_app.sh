#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/build/Downlink.app"
EXECUTABLE_DIR="$APP_DIR/Contents/MacOS"
RESOURCES_DIR="$APP_DIR/Contents/Resources"
VENDOR_BIN_DIR="$ROOT_DIR/Vendor/bin"
VENDOR_PYTHON_DIR="$ROOT_DIR/Vendor/python"
VENDOR_PLUGINS_DIR="$ROOT_DIR/Vendor/plugins"
PLUGIN_RELATIVE_PATH="downlink/yt_dlp_plugins/postprocessor/downlink_convert.py"
ICON_FILE="$ROOT_DIR/Assets/AppIcon.icns"
THIRD_PARTY_NOTICES="$ROOT_DIR/THIRD_PARTY_NOTICES.md"
APP_VERSION="26.1"
APP_BUILD="2601"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:--}"

cd "$ROOT_DIR"
swift build -c release

for required_tool in yt-dlp ffmpeg ffprobe gallery-dl; do
    if [ ! -x "$VENDOR_BIN_DIR/$required_tool" ]; then
        echo "Missing required executable: $VENDOR_BIN_DIR/$required_tool" >&2
        exit 1
    fi
done

if [ ! -d "$VENDOR_PYTHON_DIR" ]; then
    echo "Missing required Python runtime: $VENDOR_PYTHON_DIR" >&2
    exit 1
fi

if [ ! -f "$VENDOR_PLUGINS_DIR/$PLUGIN_RELATIVE_PATH" ]; then
    echo "Missing required DownlinkConvert plugin: $VENDOR_PLUGINS_DIR/$PLUGIN_RELATIVE_PATH" >&2
    exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$EXECUTABLE_DIR" "$RESOURCES_DIR"
cp ".build/release/Downlink" "$EXECUTABLE_DIR/Downlink"

if [ -f "$ICON_FILE" ]; then
    cp "$ICON_FILE" "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -f "$THIRD_PARTY_NOTICES" ]; then
    cp "$THIRD_PARTY_NOTICES" "$RESOURCES_DIR/THIRD_PARTY_NOTICES.md"
fi

mkdir -p "$RESOURCES_DIR/bin"
for required_tool in yt-dlp ffmpeg ffprobe gallery-dl; do
    cp -L "$VENDOR_BIN_DIR/$required_tool" "$RESOURCES_DIR/bin/$required_tool"
    chmod +x "$RESOURCES_DIR/bin/$required_tool"
done

mkdir -p "$RESOURCES_DIR/python"
cp -R "$VENDOR_PYTHON_DIR/"* "$RESOURCES_DIR/python/"
find "$RESOURCES_DIR/python" -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete
find "$RESOURCES_DIR/python" -type d -name '__pycache__' -empty -delete

mkdir -p "$RESOURCES_DIR/plugins/$(dirname "$PLUGIN_RELATIVE_PATH")"
cp "$VENDOR_PLUGINS_DIR/$PLUGIN_RELATIVE_PATH" "$RESOURCES_DIR/plugins/$PLUGIN_RELATIVE_PATH"

for required_tool in yt-dlp ffmpeg ffprobe gallery-dl; do
    if [ ! -x "$RESOURCES_DIR/bin/$required_tool" ]; then
        echo "Packaged tool is missing or not executable: $RESOURCES_DIR/bin/$required_tool" >&2
        exit 1
    fi
done

if [ ! -f "$RESOURCES_DIR/plugins/$PLUGIN_RELATIVE_PATH" ]; then
    echo "Packaged tool is missing: $RESOURCES_DIR/plugins/$PLUGIN_RELATIVE_PATH" >&2
    exit 1
fi

if [ -n "$(find "$RESOURCES_DIR" \( -type d -name '__pycache__' -o -type f \( -name '*.pyc' -o -name '*.pyo' \) \) -print -quit)" ]; then
    echo "Packaged resources contain writable Python bytecode caches" >&2
    exit 1
fi

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
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
    <string>$APP_VERSION</string>
    <key>CFBundleVersion</key>
    <string>$APP_BUILD</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

codesign --force --deep --sign "$CODESIGN_IDENTITY" --timestamp=none "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

echo "Built $APP_DIR version $APP_VERSION ($APP_BUILD)"
