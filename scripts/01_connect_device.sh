#!/usr/bin/env bash
# Connects to an Amazon Fire TV device over Wi-Fi ADB.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2}}"
PORT="${2:-${PORT:-5555}}"

echo "=== Connecting to Amazon Fire TV at ${TV_IP}:${PORT} ==="
adb connect "${TV_IP}:${PORT}"
adb -s "${TV_IP}:${PORT}" wait-for-device

DEVICE_MODEL=$(adb -s "${TV_IP}:${PORT}" shell getprop ro.product.model | tr -d '\r')
DEVICE_BOARD=$(adb -s "${TV_IP}:${PORT}" shell getprop ro.product.name | tr -d '\r')
FIREOS_VER=$(adb -s "${TV_IP}:${PORT}" shell getprop ro.build.version.name | tr -d '\r')
SDK_VER=$(adb -s "${TV_IP}:${PORT}" shell getprop ro.build.version.sdk | tr -d '\r')

echo "Target Device: ${DEVICE_MODEL} (${DEVICE_BOARD})"
echo "Fire OS Version: ${FIREOS_VER} (Android SDK ${SDK_VER})"
echo "Connection verified successfully."
