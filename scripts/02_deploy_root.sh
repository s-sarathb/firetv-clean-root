#!/usr/bin/env bash
# Deploys and verifies GhostLock root daemon on Fire TV Stick (Fire OS 7 / MT8695/MT8696).
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
ADB="adb -s ${TV_IP}"

echo "=== Checking Root Status on ${TV_IP} ==="

STATUS=$($ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
if echo "$STATUS" | grep -q "uid=0(root)"; then
    echo "[✓] Root is already active: $STATUS"
    exit 0
fi

echo "[*] GhostLock daemon not running or su inactive. Starting daemon..."
$ADB shell "nohup /data/local/tmp/gl/ghostlock_root > /data/local/tmp/gl/daemon.log 2>&1 &"
sleep 2

MAX_RETRIES=10
for i in $(seq 1 $MAX_RETRIES); do
    STATUS=$($ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
    if echo "$STATUS" | grep -q "uid=0(root)"; then
        echo "[✓] Root daemon successfully initialized!"
        echo "Root Identity: $STATUS"
        echo "SELinux Mode: $($ADB shell getenforce | tr -d '\r')"
        exit 0
    fi
    echo "Waiting for exploit completion... ($i/$MAX_RETRIES)"
    sleep 1
done

echo "[!] Failed to start root daemon. Check logs:"
$ADB shell "cat /data/local/tmp/gl/daemon.log | tail -n 20"
exit 1
