#!/usr/bin/env bash
# One-line Fire TV original state restoration.
# Re-enables the stock Amazon launcher, OOBE, and debloated services.
# NOTE: This does NOT wipe data or factory reset the device. All apps and user logins remain intact.
#
# Usage:
#   ./restore.sh 192.168.1.50
#   or: TV_HOST=192.168.1.50 ./restore.sh

set -euo pipefail
cd "$(dirname "$0")"

TV_HOST="${1:-${TV_HOST:-}}"
if [ -z "$TV_HOST" ]; then
    echo "Usage: ./restore.sh <TV_IP_ADDRESS>" >&2
    exit 1
fi

case "$TV_HOST" in
    *:*) TARGET="$TV_HOST" ;;
    *)   TARGET="${TV_HOST}:5555" ;;
esac

echo "=========================================================="
echo " Restoring Fire TV to Original State"
echo " (Does NOT factory reset; preserves all app data)"
echo " Target: $TARGET"
echo "=========================================================="

ADB="adb -s $TARGET"
adb connect "$TARGET" >/dev/null 2>&1 || true
$ADB wait-for-device

echo "[1/4] Re-enabling stock Amazon launcher..."
$ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 com.amazon.tv.launcher 2>/dev/null || pm enable com.amazon.tv.launcher'"
$ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 com.amazon.tv.oobe 2>/dev/null || pm enable com.amazon.tv.oobe || true'"
$ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 com.amazon.firehomestarter 2>/dev/null || pm enable com.amazon.firehomestarter || true'"

echo "[2/4] Resetting default HOME to stock launcher..."
STOCK_ACT=$($ADB shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME com.amazon.tv.launcher" | tail -n 1 | tr -d '\r')
if [ -n "$STOCK_ACT" ]; then
    $ADB shell "/data/local/tmp/gl/su -c 'cmd package set-home-activity --user 0 $STOCK_ACT'"
fi

echo "[3/4] Re-enabling debloated packages..."
PROFILE="profiles/sheldon_lite_fireos7.txt"
if [ -f "$PROFILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        pkg=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$pkg" ] && continue
        $ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 $pkg 2>/dev/null || pm enable $pkg 2>/dev/null || true'"
    done < "$PROFILE"
fi

echo "[4/4] Resetting Private DNS to opportunistic..."
$ADB shell "/data/local/tmp/gl/su -c 'settings put global private_dns_mode opportunistic'"

$ADB shell "input keyevent 3"
echo "Original Amazon launcher and services restored."
