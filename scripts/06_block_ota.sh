#!/usr/bin/env bash
# Permanently disables Amazon OTA update services to prevent firmware regression.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
ADB="adb -s ${TV_IP}"

echo "=== Blocking Amazon OTA Updates on $TV_IP ==="

OTA_PACKAGES="
com.amazon.device.software.ota
com.amazon.device.software.ota.override
com.amazon.tv.forcedotaupdater.v2
"

for pkg in $OTA_PACKAGES; do
    echo "Disabling $pkg..."
    $ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null || true'"
    $ADB shell "/data/local/tmp/gl/su -c 'pm clear $pkg 2>/dev/null || true'"
done

echo "[✓] OTA updates permanently blocked."
