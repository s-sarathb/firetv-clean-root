#!/usr/bin/env bash
# One-line Fire TV cleanup: debloats Fire OS, blocks OTAs, and installs CleanYourTV as native default Home.
# Usage:
#   ./clean.sh 192.168.1.50
#   or: TV_HOST=192.168.1.50 ./clean.sh

set -euo pipefail
cd "$(dirname "$0")"

TV_HOST="${1:-${TV_HOST:-}}"
if [ -z "$TV_HOST" ]; then
    echo "Usage: ./clean.sh <TV_IP_ADDRESS>" >&2
    echo "Example: ./clean.sh 192.168.1.50" >&2
    exit 1
fi

case "$TV_HOST" in
    *:*) TARGET="$TV_HOST" ;;
    *)   TARGET="${TV_HOST}:5555" ;;
esac

echo "=========================================================="
echo " FireTV Clean Root: One-Line Native Setup"
echo " Target: $TARGET"
echo "=========================================================="

ADB="adb -s $TARGET"

# 1. Connect over ADB
echo "[1/7] Connecting to device..."
adb connect "$TARGET" >/dev/null 2>&1 || true
$ADB wait-for-device

MODEL=$($ADB shell getprop ro.product.model | tr -d '\r')
BOARD=$($ADB shell getprop ro.product.name | tr -d '\r')
FIREOS=$($ADB shell getprop ro.build.version.name | tr -d '\r')
echo "Connected: $MODEL ($BOARD) running $FIREOS"

# 2. Check/Initialize GhostLock Root Daemon
echo "[2/7] Checking root access (GhostLock)..."
STATUS=$($ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
if ! echo "$STATUS" | grep -q "uid=0(root)"; then
    echo "Root daemon not active. Starting /data/local/tmp/gl/ghostlock_root..."
    $ADB shell "nohup /data/local/tmp/gl/ghostlock_root > /data/local/tmp/gl/daemon.log 2>&1 &"
    sleep 2
    for i in {1..8}; do
        STATUS=$($ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
        if echo "$STATUS" | grep -q "uid=0(root)"; then break; fi
        sleep 1
    done
fi

if ! echo "$STATUS" | grep -q "uid=0(root)"; then
    echo "ERROR: GhostLock root daemon failed to start on $TARGET." >&2
    echo "Ensure GhostLock binary is placed in /data/local/tmp/gl/ghostlock_root." >&2
    exit 1
fi
echo "Root verified: $STATUS"

# 3. Debloat Telemetry, Metrics & Ads
echo "[3/7] Debloating telemetry, analytics, and recommendation services..."
PROFILE="profiles/sheldon_lite_fireos7.txt"

# Critical load-bearing packages that must NEVER be touched
WHITELIST="com.amazon.tv.settings.v2 com.amazon.tv.ime com.onnet.systems.iptv.pioneer"

if [ -f "$PROFILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        pkg=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$pkg" ] && continue

        # Safety guard
        for safe in $WHITELIST; do
            if [ "$pkg" = "$safe" ]; then continue 2; fi
        done

        $ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null || true'"
    done < "$PROFILE"
    echo "Debloat profile applied."
fi

# 4. Configure AdGuard Private DNS
echo "[4/7] Setting AdGuard Private DNS (ad and tracker blocking)..."
$ADB shell "/data/local/tmp/gl/su -c 'settings put global private_dns_specifier dns.adguard-dns.com; settings put global private_dns_mode hostname'"

# 5. Install CleanYourTV Launcher
echo "[5/7] Installing CleanYourTV native launcher..."
APK="launcher/cleanyourtv-release.apk"
if [ ! -f "$APK" ]; then
    echo "ERROR: $APK not found!" >&2
    exit 1
fi

$ADB install -r "$APK"
$ADB shell "/data/local/tmp/gl/su -c 'pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true'"
$ADB shell "/data/local/tmp/gl/su -c 'cmd package compile -m speed -f com.gathin.tvhome'"

# 6. Disable Stock Launcher & Bind CleanYourTV as Native HOME
echo "[6/7] Disabling stock Amazon launcher and binding CleanYourTV as HOME..."
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.tv.launcher 2>/dev/null || pm disable com.amazon.tv.launcher'"
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.tv.oobe 2>/dev/null || pm disable com.amazon.tv.oobe || true'"
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.firehomestarter 2>/dev/null || pm disable com.amazon.firehomestarter || true'"

$ADB shell "/data/local/tmp/gl/su -c 'cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity'"

# 7. Block OTA Updates & Check Hotstar Kiwi DRM
echo "[7/7] Neutralizing OTA updaters and checking streaming dependencies..."
OTA_PKGS="com.amazon.device.software.ota com.amazon.device.software.ota.override com.amazon.tv.forcedotaupdater.v2"
for ota in $OTA_PKGS; do
    $ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 $ota 2>/dev/null || pm disable $ota 2>/dev/null || true'"
    $ADB shell "/data/local/tmp/gl/su -c 'pm clear $ota 2>/dev/null || true'"
done

# Check if Hotstar is installed and pre-compile
if $ADB shell "pm path in.startv.hotstar" >/dev/null 2>&1; then
    echo "Hotstar detected: compiling dex2oat for seamless playback..."
    $ADB shell "/data/local/tmp/gl/su -c 'cmd package compile -m speed -f in.startv.hotstar'"
fi

# Bring launcher to front
$ADB shell "am start -n com.gathin.tvhome/.MainActivity"
$ADB shell "input keyevent 3"

echo ""
echo "=========================================================="
echo " Finished! CleanYourTV is now the native Home launcher."
echo " Press Home on your Fire TV remote to verify."
echo "=========================================================="
