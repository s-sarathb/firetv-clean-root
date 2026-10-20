#!/usr/bin/env bash
# Restores stock Amazon Fire TV launcher and re-enables disabled components.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
PROFILE="${2:-profiles/sheldon_lite_fireos7.txt}"
ADB="adb -s ${TV_IP}"

echo "=== Restoring Amazon Stock Environment on $TV_IP ==="

echo "[*] Re-enabling stock Amazon Launcher..."
$ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 com.amazon.tv.launcher 2>/dev/null || pm enable com.amazon.tv.launcher'"
$ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 com.amazon.firehomestarter 2>/dev/null || pm enable com.amazon.firehomestarter || true'"

echo "[*] Rebinding HOME to stock launcher..."
$ADB shell "/data/local/tmp/gl/su -c 'cmd package set-home-activity --user 0 com.amazon.tv.launcher/.ui.HomeActivity_vNext'"

if [ -f "$PROFILE" ]; then
    echo "[*] Re-enabling packages from $PROFILE..."
    while IFS= read -r line || [ -n "$line" ]; do
        clean_line=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
        [ -z "$clean_line" ] && continue
        $ADB shell "/data/local/tmp/gl/su -c 'pm enable --user 0 $clean_line 2>/dev/null || pm enable $clean_line 2>/dev/null || true'"
    done < "$PROFILE"
fi

echo "[*] Resetting Private DNS to opportunistic..."
$ADB shell "/data/local/tmp/gl/su -c 'settings put global private_dns_mode opportunistic'"

echo "[✓] Device restored to stock state."
