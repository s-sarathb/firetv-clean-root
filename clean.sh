#!/usr/bin/env bash
# One-line Fire TV cleanup: debloats Fire OS, blocks OTAs, and installs CleanYourTV as native default Home.
#
# Usage:
#   ./clean.sh 192.168.1.50
#   ./clean.sh 192.168.1.50 --launcher-only
#   ./clean.sh 192.168.1.50 --debloat-only
#   ./clean.sh 192.168.1.50 --build
#   TV_HOST=192.168.1.50 ./clean.sh

set -euo pipefail
cd "$(dirname "$0")"

TV_HOST=""
MODE="full"
BUILD_SOURCE=0

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --launcher-only) MODE="launcher"; shift ;;
        --debloat-only)  MODE="debloat"; shift ;;
        --build)         BUILD_SOURCE=1; shift ;;
        --help|-h)
            echo "Usage: $0 <TV_IP_ADDRESS> [--launcher-only | --debloat-only | --build]"
            exit 0 ;;
        *)
            if [ -z "$TV_HOST" ]; then TV_HOST="$1"; shift;
            else echo "Unknown argument: $1" >&2; exit 1; fi ;;
    esac
done

TV_HOST="${TV_HOST:-${TV_HOST_ENV:-}}"
if [ -z "$TV_HOST" ]; then
    echo "Usage: ./clean.sh <TV_IP_ADDRESS> [options]" >&2
    echo "Example: ./clean.sh 192.168.1.50" >&2
    exit 1
fi

case "$TV_HOST" in
    *:*) TARGET="$TV_HOST" ;;
    *)   TARGET="${TV_HOST}:5555" ;;
esac

echo "=========================================================="
echo " FireTV Clean Root (Mode: $MODE)"
echo " Target: $TARGET"
echo "=========================================================="

ADB="adb -s $TARGET"

# Execute a shell command as root via GhostLock with 15s timeout
su_exec() {
    timeout 15s $ADB shell "/data/local/tmp/gl/su -c '$*'"
}

# 1. Connect over ADB with strict timeouts
check_connection() {
    echo "[1/6] Connecting to device..."
    timeout 5s adb connect "$TARGET" >/dev/null 2>&1 || true
    if ! timeout 8s $ADB wait-for-device; then
        echo "ERROR: Connection timed out. Make sure the TV is turned ON and awake." >&2
        exit 1
    fi

    MODEL=$(timeout 5s $ADB shell getprop ro.product.model | tr -d '\r')
    BOARD=$(timeout 5s $ADB shell getprop ro.product.name | tr -d '\r')
    FIREOS=$(timeout 5s $ADB shell getprop ro.build.version.name | tr -d '\r')
    echo "Connected: $MODEL ($BOARD) running $FIREOS"
}

# 2. Check/Initialize GhostLock Root Daemon
check_root() {
    echo "[2/6] Checking root access (GhostLock)..."
    STATUS=$(timeout 5s $ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
    if ! echo "$STATUS" | grep -q "uid=0(root)"; then
        echo "Root daemon not active. Starting /data/local/tmp/gl/ghostlock_root..."
        timeout 5s $ADB shell "nohup /data/local/tmp/gl/ghostlock_root > /data/local/tmp/gl/daemon.log 2>&1 &"
        sleep 2
        for i in {1..8}; do
            STATUS=$(timeout 5s $ADB shell "/data/local/tmp/gl/su -c 'id'" 2>&1 || true)
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
}

# 3. Debloat Telemetry, Metrics & Ads
debloat_system() {
    echo "[3/6] Debloating telemetry, analytics, and recommendation services..."
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

            su_exec "pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null || true"
        done < "$PROFILE"
        echo "Debloat profile applied."
    fi

    # Set AdGuard Private DNS
    echo "Setting AdGuard Private DNS (ad and tracker blocking)..."
    su_exec "settings put global private_dns_specifier dns.adguard-dns.com; settings put global private_dns_mode hostname"
}

# 4. Custom Launcher Installation & Safe Handover
install_launcher() {
    echo "[4/6] Installing CleanYourTV custom launcher..."
    APK="launcher/cleanyourtv-release.apk"

    # Optional: Build from source if requested or missing
    if [ "$BUILD_SOURCE" -eq 1 ] || [ ! -f "$APK" ]; then
        if [ -d "launcher/app" ] && [ -x "launcher/gradlew" ]; then
            echo "Building CleanYourTV APK from source..."
            (cd launcher && ./gradlew assembleRelease -q)
            APK="launcher/app/build/outputs/apk/release/app-release.apk"
        elif [ ! -f "$APK" ]; then
            echo "ERROR: Launcher APK not found at $APK and source not available to build." >&2
            exit 1
        fi
    fi

    # Method 1: Push APK to staging area with timeout
    echo "Pushing $APK to device..."
    if ! timeout 30s $ADB push "$APK" /data/local/tmp/cleanyourtv.apk >/dev/null; then
        echo "ERROR: File push timed out over Wi-Fi." >&2
        exit 1
    fi

    # Method 2: Install APK with validation
    echo "Installing launcher package..."
    INSTALL_OUT=$(su_exec "pm install -r /data/local/tmp/cleanyourtv.apk; rm -f /data/local/tmp/cleanyourtv.apk")
    echo "$INSTALL_OUT"
    if ! echo "$INSTALL_OUT" | grep -q "Success"; then
        echo "ERROR: Launcher install failed; stock launcher left untouched." >&2
        exit 1
    fi

    # Method 3: Grant permissions and compile AOT
    echo "Granting permissions and optimizing bytecode (dex2oat)..."
    su_exec "pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION 2>/dev/null || true"
    su_exec "cmd package compile -m speed -f com.gathin.tvhome"

    # Method 4: Test launch the activity BEFORE touching stock launcher
    echo "Testing launcher startup (am start -W)..."
    START_OUT=$(timeout 10s $ADB shell "am start -W -n com.gathin.tvhome/.MainActivity" 2>&1 || true)
    echo "$START_OUT"
    if echo "$START_OUT" | grep -qi "Error"; then
        echo "ERROR: CleanYourTV activity failed to start; stock launcher left enabled." >&2
        exit 1
    fi

    # Method 5: Disable stock Amazon launcher
    echo "Disabling stock Amazon launcher and setup wrappers..."
    su_exec "pm disable-user --user 0 com.amazon.tv.launcher 2>/dev/null || pm disable com.amazon.tv.launcher"
    su_exec "pm disable-user --user 0 com.amazon.tv.oobe 2>/dev/null || pm disable com.amazon.tv.oobe || true"
    su_exec "pm disable-user --user 0 com.amazon.firehomestarter 2>/dev/null || pm disable com.amazon.firehomestarter || true"

    # Method 6: Bind default HOME activity
    echo "Setting CleanYourTV as default Home activity..."
    su_exec "cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"

    # Method 7: Post-handover verification & rollback check
    HOME_NOW=$(timeout 5s $ADB shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME" | tail -n 1 | tr -d '\r')
    case "$HOME_NOW" in
        com.gathin.tvhome/*)
            echo "Home successfully resolved to: $HOME_NOW"
            ;;
        *)
            echo "WARNING: Home resolved to '$HOME_NOW' instead of CleanYourTV. Rolling back..." >&2
            su_exec "pm enable --user 0 com.amazon.tv.launcher 2>/dev/null || true"
            exit 1
            ;;
    esac

    # Method 8: Optional key accessibility services
    if [ "${HOME_KEY_SERVICE:-0}" = 1 ]; then
        echo "Enabling HomeKeyService for remotes sending KEYCODE_ALL_APPS..."
        su_exec "settings put secure enabled_accessibility_services com.gathin.tvhome/.HomeKeyService; settings put secure accessibility_enabled 1"
    fi
}

# 5. Block Amazon OTA Updates
block_ota() {
    echo "[5/6] Neutralizing OTA updaters..."
    OTA_PKGS="com.amazon.device.software.ota com.amazon.device.software.ota.override com.amazon.tv.forcedotaupdater.v2"
    for ota in $OTA_PKGS; do
        su_exec "pm disable-user --user 0 $ota 2>/dev/null || pm disable $ota 2>/dev/null || true"
        su_exec "pm clear $ota 2>/dev/null || true"
    done
}

# 6. Check Streaming App Dependencies (Hotstar Kiwi DRM)
check_streaming_deps() {
    echo "[6/6] Verifying streaming app dependencies..."
    if timeout 5s $ADB shell "pm path in.startv.hotstar" >/dev/null 2>&1; then
        echo "Hotstar detected. Compiling dex2oat..."
        echo "Notice: Modifying Hotstar smali bytecode carries potential risk of account suspension if backend integrity checks detect altered signatures. Use at your own risk."
        su_exec "cmd package compile -m speed -f in.startv.hotstar"
    fi

    # Trigger Home key to bring launcher to front
    timeout 5s $ADB shell "am start -n com.gathin.tvhome/.MainActivity >/dev/null 2>&1 || true"
    timeout 5s $ADB shell "input keyevent 3"
}

# Execution Pipeline
check_connection
check_root

if [ "$MODE" = "full" ] || [ "$MODE" = "debloat" ]; then
    debloat_system
fi

if [ "$MODE" = "full" ] || [ "$MODE" = "launcher" ]; then
    install_launcher
fi

if [ "$MODE" = "full" ]; then
    block_ota
    check_streaming_deps
fi

echo ""
echo "=========================================================="
echo " Finished! CleanYourTV is now the native Home launcher."
echo " Press Home on your Fire TV remote to verify."
echo "=========================================================="
