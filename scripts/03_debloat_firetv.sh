#!/usr/bin/env bash
# Disables Fire TV bloatware, metrics, recommendation engines, and ad syncers.
set -euo pipefail

TV_IP="${1:-${TV_IP:-192.168.1.2:5555}}"
PROFILE="${2:-profiles/sheldon_lite_fireos7.txt}"
ADB="adb -s ${TV_IP}"

echo "=== Fire TV Debloat Routine ==="
echo "Target: ${TV_IP}"
echo "Profile: ${PROFILE}"

if [ ! -f "$PROFILE" ]; then
    echo "ERROR: Profile file '$PROFILE' not found!" >&2
    exit 1
fi

# Critical safety whitelist
PROTECTED_APPS="com.onnet.systems.iptv.pioneer in.startv.hotstar com.amazon.tv.settings.v2 com.amazon.tv.ime"

while IFS= read -r line || [ -n "$line" ]; do
    # Skip comments and blank lines
    clean_line=$(echo "$line" | sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    [ -z "$clean_line" ] && continue

    pkg="$clean_line"

    # Whitelist guard
    for protected in $PROTECTED_APPS; do
        if [ "$pkg" = "$protected" ]; then
            echo "[GUARD] Skipping whitelisted package: $pkg"
            continue 2
        fi
    done

    echo "Disabling: $pkg"
    $ADB shell "/data/local/tmp/gl/su -c 'pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null || true'"
done < "$PROFILE"

echo "=== Applying Private DNS (AdGuard) ==="
$ADB shell "/data/local/tmp/gl/su -c 'settings put global private_dns_specifier dns.adguard-dns.com; settings put global private_dns_mode hostname'"

echo "[✓] Debloat routine completed successfully."
