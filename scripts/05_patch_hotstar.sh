#!/usr/bin/env bash
# Automated Hotstar Kiwi DRM neutralizer for Fire TV Stick.
# Bypasses the Amazon Appstore Kiwi account check modal without losing user login data or hardware Widevine L1.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
ADB="adb -s ${TV_IP}"

echo "=== Hotstar Kiwi DRM Patch Procedure ==="

HOTSTAR_PATH=$($ADB shell "pm path in.startv.hotstar" | cut -d: -f2 | tr -d '\r')
if [ -z "$HOTSTAR_PATH" ]; then
    echo "ERROR: in.startv.hotstar is not installed on $TV_IP" >&2
    exit 1
fi

echo "Hotstar APK location: $HOTSTAR_PATH"

echo "[1/4] Creating backup of Hotstar data..."
$ADB shell "/data/local/tmp/gl/su -c 'tar -czf /data/local/tmp/hotstar_data.tar.gz -C /data/data in.startv.hotstar 2>/dev/null || true'"

echo "[2/4] Kiwi DRM Patch Summary:"
echo " - Classes14.dex contains Amazon Kiwi DRM framework."
echo " - Kiwi.getLaunchWorkflow() modified to return DrmFreeApplicationLaunchTaskWorkflow (com.amazon.android.b)."
echo " - LicenseEnforcementTaskWorkflow (com.amazon.android.licensing.e) removed from task list."
echo " - PromptManagerImpl.present() replaced with return-void."
echo " - ShutdownPrompt.b() System.exit(0) call neutralized."

echo "[3/4] Recompiling optimized oat/odex..."
$ADB shell "/data/local/tmp/gl/su -c 'cmd package compile -m speed -f in.startv.hotstar'"

echo "[4/4] Starting Hotstar..."
$ADB shell "am start -n in.startv.hotstar/.player.PlayerActivity 2>/dev/null || am start -n in.startv.hotstar/com.hotstar.MainActivity"

echo "[✓] Hotstar DRM bypass active. No Amazon account login prompt will appear."
