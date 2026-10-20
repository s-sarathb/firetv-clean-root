#!/usr/bin/env bash
# Installs a clean custom launcher (CleanYourTV or Projectivy) and binds it as native default HOME.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
LAUNCHER_TYPE="${2:-cleanyourtv}" # cleanyourtv or projectivy
ADB="adb -s ${TV_IP}"

echo "=== Installing Custom Launcher ($LAUNCHER_TYPE) on $TV_IP ==="

if [ "$LAUNCHER_TYPE" = "cleanyourtv" ]; then
    APK="launcher/cleanyourtv-release.apk"
    PKG="com.gathin.tvhome"
    ACT="com.gathin.tvhome/.MainActivity"
elif [ "$LAUNCHER_TYPE" = "projectivy" ]; then
    APK="launcher/ProjectivyLauncher.apk"
    PKG="com.spocky.projengmenu"
    ACT="com.spocky.projengmenu/.ui.home.MainActivity"
else
    echo "Unknown launcher type: $LAUNCHER_TYPE (choose 'cleanyourtv' or 'projectivy')" >&2
    exit 1
fi

if [ -f "$APK" ]; then
    echo "Installing $APK..."
    $ADB install -r "$APK"
else
    echo "Local APK not found, checking if $PKG is already installed on device..."
    $ADB shell "pm path $PKG" || {
        echo "ERROR: $PKG is neither found locally nor on target device." >&2
        exit 1
    }
fi

echo "[*] Granting permissions and pre-compiling dex..."
$ADB shell "/data/local/tmp/gl/su -c 'pm grant $PKG android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true'"
$ADB shell "/data/local/tmp/gl/su -c 'cmd package compile -m speed -f $PKG'"

echo "[*] Disabling stock Amazon launcher and setup wrappers..."
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.tv.launcher 2>/dev/null || pm disable com.amazon.tv.launcher'"
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.tv.oobe 2>/dev/null || pm disable com.amazon.tv.oobe || true'"
$ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 com.amazon.firehomestarter 2>/dev/null || pm disable com.amazon.firehomestarter || true'"

echo "[*] Setting $ACT as default HOME..."
$ADB shell "/data/local/tmp/gl/su -c 'cmd package set-home-activity --user 0 $ACT'"

echo "[*] Starting launcher..."
$ADB shell "am start -n $ACT"
$ADB shell "input keyevent 3"

echo "[OK] Verifying resolved HOME activity:"
$ADB shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
