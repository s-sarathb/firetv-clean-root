# Architecture & Reverse Engineering Deep-Dive

## 1. The Fire OS Lockdown Model

Amazon Fire OS is a heavily modified fork of Android designed around aggressive monetization, ad injection, and vendor lock-in. Unlike standard Google TV or Android TV devices, Fire OS implements multiple layers of enforcement to prevent users from replacing the home screen or removing bloatware:

### A. Protected System Packages
On standard Android TV, users can disable the stock launcher with:
```bash
pm disable-user --user 0 com.google.android.tvlauncher
```
On Fire OS, executing `pm disable-user` or `pm disable` against `com.amazon.tv.launcher`, `com.amazon.client.metrics`, or `com.amazon.tv.parentalcontrols` throws an immediate `SecurityException`:
```
java.lang.SecurityException: Cannot disable a protected package: com.amazon.tv.launcher
```
Similarly, `pm uninstall --user 0` fails with:
```
Failure [DELETE_FAILED_INTERNAL_ERROR]
```
These restrictions are hardcoded in Fire OS's custom `PackageManagerService` (`fosservices.jar` and `boot-fosframework.vdex`).

### B. Button Remapping & Accessibility Killing
Third-party solutions (such as *Launcher Manager Mini*) rely on Android's `AccessibilityService` or `dumpsys activity` polling to detect when the remote's **HOME** button (`KEYCODE_HOME`) is pressed, then quickly launch a custom launcher before the Amazon UI renders. 

Amazon actively combats this via background system watchdogs that:
1. Revoke accessibility permissions for known remap utilities after every reboot.
2. Inject a 500ms–1500ms lag between button press and launcher switch.
3. Push silent OTA updates to terminate the remapper process.

---

## 2. Root Architecture (GhostLock on Fire OS 7)

To achieve true, native launcher replacement without lag or accessibility hacks, we leverage the **GhostLock** kernel exploit targeting MediaTek MT8695/MT8696 SoCs (Cortex-A53 / Mali-G52) running Fire OS 7 (Linux Kernel 4.9 LTS).

```
+-------------------------------------------------------------+
|                     User Space                              |
|  [CleanYourTV Launcher]   [Projectivy]   [JioHotstar]       |
|              \                  |             /             |
|               v                 v            v              |
|        cmd package set-home-activity --user 0               |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                GhostLock Root Daemon                        |
|  - Socket: @ghostlock_root                                  |
|  - Binary: /data/local/tmp/gl/su -> /system/xbin/su         |
|  - Capabilities: cap_effective=0000003fffffffff             |
+-------------------------------------------------------------+
                               |
                               v
+-------------------------------------------------------------+
|                   Kernel Space                              |
|  - SELinux: Permissive (status base patched, enforcing 1->0)|
|  - Kernel Credentials: UID/GID 0 injected into task struct   |
+-------------------------------------------------------------+
```

### Exploit Sequence:
1. **Heap Grooming:** Shapes `mm_struct` slab caches and allocates 4,096 full-page `AF_UNIX` payloads.
2. **Requeue PI Primitive:** Triggers `LOCK_PI`, `WAIT_REQUEUE_PI`, and `CMP_REQUEUE_PI` to gain arbitrary kernel read/write (`krw`).
3. **Credential Overwrite:** Locates `init_task` in kernel memory, walks the task struct list to find `ghostlock_root`, and zeroes `real_cred` UID/GID fields (`uid=0`, `gid=0`).
4. **SELinux Neutralization:** Modifies the kernel status vector (`enforcing 1->0`), placing SELinux into permissive mode without modifying the boot partition.
5. **Daemon Socket:** Binds `@ghostlock_root` listening for client requests and provides standard `su` execution.

---

## 3. Native Home Screen Replacement

With UID 0 and permissive SELinux, the `PackageManagerService` restrictions no longer apply to root commands:

```bash
# 1. Disable stock launcher and home wrappers
/data/local/tmp/gl/su -c "pm disable-user --user 0 com.amazon.tv.launcher"
/data/local/tmp/gl/su -c "pm disable-user --user 0 com.amazon.firehomestarter"
/data/local/tmp/gl/su -c "pm disable-user --user 0 com.amazon.tv.oobe"

# 2. Register CleanYourTV as default HOME
/data/local/tmp/gl/su -c "cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"
```

Because `set-home-activity` sets Android's internal `preferred-activities` resolver directly in `/data/system/users/0/package-restrictions.xml`:
* Pressing the **HOME** button immediately triggers `Intent.CATEGORY_HOME`.
* Android routes the intent directly to `com.gathin.tvhome/.MainActivity`.
* **Latency is 0 ms.** No accessibility services, no watchers, no flicker.

---

## 4. OTA Neutralization

To prevent Amazon from pushing silent OTA updates that overwrite the package configuration:

```bash
pm disable-user --user 0 com.amazon.device.software.ota
pm disable com.amazon.device.software.ota.override
pm disable-user --user 0 com.amazon.tv.forcedotaupdater.v2
pm clear com.amazon.device.software.ota
```
This severs the device's ability to pull delta OTAs from Amazon servers.
