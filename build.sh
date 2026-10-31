#!/bin/zsh
# Construit NotifSilence.app dans ./build.
# Usage : ./build.sh            -> construit
#         ./build.sh install    -> construit puis copie dans /Applications et lance
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="NotifSilence"
APP="build/$APP_NAME.app"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>      <string>NotifSilence</string>
    <key>CFBundleExecutable</key>       <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>       <string>com.alkbron.notifsilence</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key>          <string>1</string>
    <key>LSMinimumSystemVersion</key>   <string>13.0</string>
    <key>LSUIElement</key>              <true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "✅ $APP"

if [[ "${1:-}" == "install" ]]; then
    pkill -x "$APP_NAME" || true
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP" /Applications/
    open "/Applications/$APP_NAME.app"
    echo "✅ Installé dans /Applications et lancé"
fi
