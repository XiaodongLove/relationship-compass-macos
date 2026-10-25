#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="DayPlanner"
BUILD_DIR="$ROOT/.build"
APP_DIR="$BUILD_DIR/App/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "==> Building release $APP_NAME"
swift build -c release --product DayPlanner

BIN="$(swift build -c release --product DayPlanner --show-bin-path)/DayPlanner"
if [[ ! -x "$BIN" ]]; then
  # Some SPM layouts put products under out/Products
  ALT="$ROOT/.build/out/Products/Release/DayPlanner"
  if [[ -x "$ALT" ]]; then
    BIN="$ALT"
  else
    echo "error: DayPlanner binary not found after release build" >&2
    find "$ROOT/.build" -name DayPlanner -type f 2>/dev/null | head -20 >&2 || true
    exit 1
  fi
fi

echo "==> Packaging $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$RESOURCES"
cp "$BIN" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

cat > "$CONTENTS/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>DayPlanner</string>
  <key>CFBundleIdentifier</key>
  <string>local.dayplanner.app</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>每日工作计划</string>
  <key>CFBundleDisplayName</key>
  <string>每日工作计划</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <false/>
  <key>NSCalendarsFullAccessUsageDescription</key>
  <string>「每日工作计划」会在今日计划旁显示系统日历中的日程。</string>
  <key>NSRemindersFullAccessUsageDescription</key>
  <string>「每日工作计划」可选择将未完成的提醒事项导入收件箱。</string>
  <key>NSUserNotificationsUsageDescription</key>
  <string>「每日工作计划」会发送你为任务设置的本地提醒。</string>
</dict>
</plist>
PLIST

echo "==> Packaged: $APP_DIR"
echo "$APP_DIR"
