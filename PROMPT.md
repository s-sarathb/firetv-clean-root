# The prompt

Paste this into Claude Code, Antigravity, Gemini CLI, Cursor, or another coding assistant with shell access on a computer that is on the same Wi-Fi as the Fire TV. Works on Amazon Fire TV Stick Lite (`sheldon`), Fire TV Stick 3rd Gen (`sheldonp`), Fire TV Stick 4K (`mantis`), and 4K Max (`kara`) running Fire OS 7 or Fire OS 6.

If you cloned this repo, mention that: the assistant can run `clean.sh` directly, inspect `profiles/`, and use `launcher/cleanyourtv-release.apk`.

Before you start, on the TV: Settings > My Fire TV > About > highlight your device name and press the select button 7 times to enable Developer options, then go back > Developer options > turn on **ADB debugging**. Keep the TV on.

---

I want to debloat my Amazon Fire TV Stick, permanently disable the ad-filled stock launcher, and replace it with the clean Apple TV-style CleanYourTV launcher with 0 ms Home button latency.
My Fire TV model or IP is: <IP ADDRESS OR MODEL HERE>. Work on the real device, step by step. Do not guess; verify everything you do over ADB.

Connect
- Connect to the Fire TV over ADB on port 5555 (`adb connect <IP>:5555`).
- Query `getprop ro.product.model`, `ro.product.name`, and `ro.build.version.name` to identify the device and Fire OS version.
- Use explicit timeouts on connection commands (`timeout 8s adb wait-for-device`) so dropped Wi-Fi packets or device sleep do not cause indefinite terminal hangs.
- If the device is unauthenticated, tell me to accept the "Allow USB debugging?" prompt on the TV screen.

Root Access (GhostLock)
- Check if root is active: `adb shell "/data/local/tmp/gl/su -c 'id'"`.
- If not running, start the in-memory GhostLock daemon (`/data/local/tmp/gl/ghostlock_root`) in the background and verify that `su -c 'id'` returns `uid=0(root)` and SELinux is permissive (`enforcing 1->0`).
- Explain that GhostLock is an in-memory kernel root based on CVE-2024-43499; it does not touch the bootloader or flash partitions.

Safety Whitelist (Never Touch)
- Never disable or modify what the TV needs to work:
  - Settings (`com.amazon.tv.settings.v2`)
  - Virtual on-screen keyboard (`com.amazon.tv.ime`)
  - Remote control and Bluetooth pairing services (`com.amazon.device.bluetooth`)
  - User-installed IPTV streaming apps (specifically `com.onnet.systems.iptv.pioneer` — its credentials must never be cleared or reset).

Debloat
- Disable Amazon telemetry, analytics, crash managers, and metrics (`com.amazon.client.metrics`, `com.amazon.device.metrics`, `com.amazon.device.logmanager`, `com.amazon.device.crashmanager`, `com.amazon.ceviche`, `com.fireos.usagestats.proxy`).
- Disable Amazon ad bidding, recommendation rows, live shopping, and preloaded apps (`com.amazon.kso.blackbird`, `com.amazon.sneakpeek`, `com.amazon.shoptv.client`, `com.amazon.gamehub`, `com.amazon.tahoe`, `com.amazon.bueller.music`, `com.amazon.bueller.photos`, `com.amazon.cloud9`).
- Set system-wide Private DNS to AdGuard (`settings put global private_dns_specifier dns.adguard-dns.com` and `settings put global private_dns_mode hostname`) to block in-app trackers and banner ad domains.

Launcher
- Sideload `launcher/cleanyourtv-release.apk` (or install via `adb install -r`).
- Grant location permission (`pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION`) so the launcher displays the Wi-Fi network name.
- Pre-compile the launcher with `cmd package compile -m speed -f com.gathin.tvhome`.
- Disable the stock Amazon launcher and setup wrappers using root:
  - `pm disable-user --user 0 com.amazon.tv.launcher`
  - `pm disable-user --user 0 com.amazon.tv.oobe`
  - `pm disable-user --user 0 com.amazon.firehomestarter`
- Bind CleanYourTV as the default Home activity:
  `cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity`
- Confirm that `cmd package resolve-activity ... CATEGORY_HOME` resolves directly to `com.gathin.tvhome/.MainActivity`.

OTA Blocking & Hotstar Kiwi DRM
- Disable Amazon OTA updater services (`com.amazon.device.software.ota`, `com.amazon.tv.forcedotaupdater.v2`) so updates cannot revert the launcher settings.
- Notice on Hotstar: Warn me that modifying proprietary streaming app bytecode carries the risk of account suspension if backend security checks detect modified signatures. Ask for confirmation before modifying Hotstar smali bytecode.

Verify & Original State Reversibility
- Send `input keyevent 3` (Home key) and take a screenshot or verify with `dumpsys window` that CleanYourTV is active on screen.
- Remind me that running `./restore.sh <IP>` will bring the Fire TV back to its original Amazon state at any time without performing a factory reset or losing any app data.
