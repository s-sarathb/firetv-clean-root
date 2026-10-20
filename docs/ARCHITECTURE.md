# Technical Architecture

## 1. The Fire OS System Restrictions

Amazon Fire OS enforces restrictions inside `PackageManagerService` (`fosservices.jar` and `boot-fosframework.vdex`):

### Protected System Packages
Executing `pm disable-user` or `pm disable` against `com.amazon.tv.launcher`, `com.amazon.client.metrics`, or `com.amazon.tv.parentalcontrols` throws a `SecurityException`:
```
java.lang.SecurityException: Cannot disable a protected package: com.amazon.tv.launcher
```
Executing `pm uninstall --user 0` fails with:
```
Failure [DELETE_FAILED_INTERNAL_ERROR]
```

### Accessibility Hijacker Pitfalls
Third-party utilities like Launcher Manager Mini rely on an `AccessibilityService` to listen for `KEYCODE_HOME` events. Once detected, they launch the alternative launcher on top of Amazon's home activity. This leads to:
1. A noticeable 500–1500 ms delay where the user sees the Amazon UI render before switching.
2. Background watchdogs revoking accessibility permissions after reboots.
3. Silent background OTA updates breaking the accessibility service.

---

## 2. Kernel Root via GhostLock

To bypass `PackageManagerService` restrictions natively, we use [GhostLock](https://github.com/R0rt1z2/GhostLock) by [R0rt1z2](https://github.com/R0rt1z2).

### Exploit Overview (CVE-2024-43499)
- **Target:** Linux kernel 4.9.117 (MediaTek MT8695/MT8696 platforms on Fire OS 7).
- **Vulnerability:** Use-after-free vulnerability in the futex priority-inheritance (`rt_mutex`) subsystem.
- **Primitive:** Leverages `LOCK_PI`, `WAIT_REQUEUE_PI`, and `CMP_REQUEUE_PI` to gain arbitrary kernel read/write (`krw`).
- **Privilege Escalation:** Traverses the task list to locate `ghostlock_root` and zeroes `real_cred` UID/GID fields to achieve `uid=0`, `gid=0`, and full capabilities (`cap_effective=0000003fffffffff`).
- **SELinux Patching:** Overwrites the kernel status vector (`enforcing 1->0`) in-memory, transitioning SELinux to permissive without modifying the read-only boot partition.
- **Daemon Socket:** The binary stays resident in memory, listening on abstract socket `@ghostlock_root` to service root requests via `/data/local/tmp/gl/su` or symlinked `/system/xbin/su`.

---

## 3. Direct Native HOME Registration

With root privileges active, package manager restrictions are bypassed:

```bash
# 1. Disable the stock launcher and setup wrappers
su -c "pm disable-user --user 0 com.amazon.tv.launcher"
su -c "pm disable-user --user 0 com.amazon.firehomestarter"
su -c "pm disable-user --user 0 com.amazon.tv.oobe"

# 2. Assign custom launcher as the default HOME activity
su -c "cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity"
```

Because `cmd package set-home-activity` writes directly into the package preferences database (`/data/system/users/0/package-restrictions.xml`):
- Hardware Home button events are routed directly to `com.gathin.tvhome` by `WindowManagerService`.
- Transition delay is 0 ms.
- No accessibility services or background key loggers are required.

---

## 4. OTA Update Neutralization

To prevent Amazon updates from restoring disabled packages:

```bash
pm disable-user --user 0 com.amazon.device.software.ota
pm disable com.amazon.device.software.ota.override
pm disable-user --user 0 com.amazon.tv.forcedotaupdater.v2
pm clear com.amazon.device.software.ota
```
This isolates the device from Amazon update servers without affecting application downloads from sideloaded sources or the local network.
