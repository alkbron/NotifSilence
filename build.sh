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
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/$APP_NAME"

# Icône.
# 1) Avec Xcode 26+ : Resources/AppIcon.icon (format Icon Composer) compilé par actool.
#    C'est le seul format que macOS 26+ affiche sans le mettre dans un carré gris.
# 2) Sinon (outils en ligne de commande seuls) : Resources/AppIcon.png -> AppIcon.icns.
if xcrun actool Resources/AppIcon.icon --compile "$APP/Contents/Resources" \
        --platform macosx --minimum-deployment-target 13.0 --app-icon AppIcon \
        --output-partial-info-plist build/icon-partial.plist >/dev/null 2>&1; then
    echo "🎨 Icône compilée depuis AppIcon.icon"
else
    echo "⚠️  actool indisponible : icône .icns classique (carré gris sur macOS 26+)"
    ICONSET="build/AppIcon.iconset"
    rm -rf "$ICONSET" && mkdir -p "$ICONSET"
    for size in 16 32 128 256 512; do
        sips -z $size $size Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
        sips -z $((size * 2)) $((size * 2)) Resources/AppIcon.png --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>      <string>NotifSilence</string>
    <key>CFBundleExecutable</key>       <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>         <string>AppIcon</string>
    <key>CFBundleIconName</key>         <string>AppIcon</string>
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
