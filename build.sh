#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔨 Building GeminiUsageBar (Release)..."
swift build -c release

APP_NAME="GeminiUsageBar.app"
APP_TARGET_DIR="/Applications/$APP_NAME"
CONTENTS_DIR="$APP_TARGET_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "📦 Creating/Updating $APP_TARGET_DIR..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy binary
cp -f ".build/release/GeminiUsageBar" "$MACOS_DIR/GeminiUsageBar"

# Copy Icon if available
if [ -f "$SCRIPT_DIR/AppIcon.icns" ]; then
    cp -f "$SCRIPT_DIR/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Generate/Update Info.plist
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>GeminiUsageBar</string>
    <key>CFBundleDisplayName</key>
    <string>Gemini Usage Bar</string>
    <key>CFBundleIdentifier</key>
    <string>com.muradjabir.GeminiUsageBar</string>
    <key>CFBundleVersion</key>
    <string>1.0.5</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.5</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleExecutable</key>
    <string>GeminiUsageBar</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "🔏 Signing application bundle..."
codesign --force --deep --sign - "$APP_TARGET_DIR" 2>/dev/null || true
xattr -cr "$APP_TARGET_DIR" 2>/dev/null || true

# If --launch or -l passed, or RUN_AFTER_BUILD=1, restart the app
if [[ "$*" == *"--launch"* ]] || [[ "$*" == *"-l"* ]] || [ "$RUN_AFTER_BUILD" = "1" ]; then
    echo "🚀 Restarting app..."
    killall GeminiUsageBar 2>/dev/null || true
    sleep 0.5
    open "$APP_TARGET_DIR"
    echo "✅ GeminiUsageBar is running from /Applications!"
else
    echo "✅ Build complete! Installed to /Applications/$APP_NAME"
fi

