# Troubleshooting & Recovery

## 1. Remote Button Routing Issues
If pressing the Home button fails to open the CleanYourTV launcher:
1. Verify which package currently claims the HOME intent:
   ```bash
   adb shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
   ```
2. If it resolves to `android` (the system chooser) or an Amazon service, rebind it:
   ```bash
   adb shell "/data/local/tmp/gl/su -c 'cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity'"
   ```

## 2. GhostLock Root Daemon Lost After Reboot
GhostLock is an in-memory kernel patch that resets upon a hard power cycle. To restart it:
```bash
adb shell "nohup /data/local/tmp/gl/ghostlock_root > /data/local/tmp/gl/daemon.log 2>&1 &"
sleep 2
adb shell "/data/local/tmp/gl/su -c 'id'"
```
Once restarted, root capabilities and permissive SELinux are restored immediately.

## 3. Wi-Fi Disconnection / "No Internet"
If you applied AdGuard Private DNS and the network reports "No Internet" or an app fails to connect:
1. Revert to opportunistic DNS:
   ```bash
   adb shell "settings put global private_dns_mode opportunistic"
   ```
2. If Wi-Fi is lost completely, reconnect via Fire TV Settings:
   ```bash
   adb shell "am start -n com.amazon.tv.settings.v2/.tv.network.NetworkActivity"
   ```

## 4. Reverting to Original State
If you want to bring the device back to its original state (note: this is NOT a factory reset; all user data, accounts, and sideloaded apps are kept intact):
```bash
./restore.sh <FIRE_TV_IP>
```
This re-enables `com.amazon.tv.launcher`, restores Amazon's OOBE/HomeStarter services, and points the Home intent back to Amazon's stock home screen.
