# firetv-clean-root

Native launcher replacement, system debloat, and Appstore DRM bypass for Amazon Fire TV devices using in-memory root.

Unlike Google TV or standard Android TV, Fire OS marks its stock launcher (`com.amazon.tv.launcher`) and telemetry services as protected system packages. Standard `pm disable-user` calls fail with `SecurityException`, and button-remapping apps rely on accessibility key listeners that introduce a 500–1500 ms delay and get killed by Amazon OTA updates.

This repository pairs [GhostLock](https://github.com/R0rt1z2/GhostLock) (an in-memory kernel root exploit by R0rt1z2 based on CVE-2024-43499) with direct Android package manager calls to disable the stock launcher completely and bind [CleanYourTV](https://github.com/Gathin23/cleanyourtv) directly to `android.intent.category.HOME`. Hardware Home presses resolve instantly with 0 ms latency.

---

## Tested Hardware & Software

- **Primary Test Device:** Amazon Fire TV Stick Lite (2020, `sheldon` / `AFTSS`)
- **Firmware:** Fire OS 7.7.1.6 (Android 9 Pie, Linux Kernel 4.9.117)
- **SoC:** MediaTek MT8695D (ARM Cortex-A53, 1 GB RAM)
- **Target Compatibility:**
  - Fire TV Stick Lite / 3rd Gen (2020, `sheldon` / `sheldonp`), Fire OS 7
  - Fire TV Stick 4K 1st Gen (2018, `mantis`), Fire OS 6 / 7
  - Fire TV Stick 4K Max 1st Gen (2021, `kara`), Fire OS 7
  - Any Fire OS device with kernel vulnerability compatible with [GhostLock](https://github.com/R0rt1z2/GhostLock)

---

## What It Does

1. **Native HOME Binding:** Disables `com.amazon.tv.launcher` via root and sets CleanYourTV with `cmd package set-home-activity --user 0`. The Home button triggers the launcher at the kernel/inputflinger level without accessibility services.
2. **Telemetry & Ad Debloat:** Disables 35+ Amazon tracking, metrics, crash logging, shopping, and recommendation packages.
3. **Appstore / Kiwi DRM Patch:** Bypasses Amazon account login enforcement on sideloaded apps (e.g., JioHotstar) by neutralizing Kiwi DRM workflows while preserving MediaTek hardware decoding (`OMX.MTK.*`) and Widevine L1.
4. **OTA Neutralization:** Disables `com.amazon.device.software.ota` and `com.amazon.tv.forcedotaupdater.v2` to prevent firmware updates from overwriting configuration.
5. **Private DNS:** Sets system-wide AdGuard DNS (`dns.adguard-dns.com`) on Android 9.
6. **Safety Whitelist:** Never touches critical device services: Bluetooth remote pairing, on-screen keyboard (`com.amazon.tv.ime`), Settings (`com.amazon.tv.settings.v2`), or user-installed IPTV credentials (`com.onnet.systems.iptv.pioneer`).

---

## Repository Structure

```
firetv-clean-root/
├── docs/
│   ├── ARCHITECTURE.md          # Exploit details, SELinux patching, and Home intent routing
│   ├── DEBLOAT_LISTS.md         # Full package breakdown: safe vs load-bearing
│   ├── HOTSTAR_KIWI_PATCH.md    # Smali reverse engineering and Kiwi DRM neutralization
│   └── TROUBLESHOOTING.md       # Recovery steps, ADB fixes, and rollback
├── launcher/
│   └── cleanyourtv-release.apk  # Prebuilt CleanYourTV launcher binary (328 KB)
├── profiles/
│   ├── sheldon_lite_fireos7.txt # Debloat profile for Fire TV Stick Lite (Fire OS 7)
│   └── mantis_4k_fireos6.txt    # Debloat profile for Fire TV Stick 4K (Fire OS 6)
├── scripts/
│   ├── 01_connect_device.sh     # Network discovery and ADB connection
│   ├── 02_deploy_root.sh        # GhostLock daemon deployment and verification
│   ├── 03_debloat_firetv.sh     # Root debloat script with safety whitelist
│   ├── 04_install_launcher.sh   # Launcher installation and native Home activity binding
│   ├── 05_patch_hotstar.sh      # Automated Kiwi DRM bytecode patcher
│   ├── 06_block_ota.sh          # Amazon OTA updater blocker
│   └── restore.sh               # Full rollback script to stock Amazon launcher
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## Instructions

### 1. Enable ADB on Fire TV
1. On your Fire TV, open `Settings` > `My Fire TV` > `About`.
2. Highlight your device name and click the select button 7 times to enable Developer Options.
3. Go back one screen > `Developer Options` > turn on **ADB Debugging**.

### 2. Connect over ADB
```bash
./scripts/01_connect_device.sh <FIRE_TV_IP>
```

### 3. Initialize Root Daemon
Deploy and launch [GhostLock](https://github.com/R0rt1z2/GhostLock):
```bash
./scripts/02_deploy_root.sh <FIRE_TV_IP>
```
This executes the in-memory exploit, zeroes credential fields to gain `uid=0`, sets SELinux to permissive, and starts the root daemon at `/data/local/tmp/gl/ghostlock_root`.

### 4. Debloat System
```bash
./scripts/03_debloat_firetv.sh <FIRE_TV_IP> profiles/sheldon_lite_fireos7.txt
```

### 5. Install CleanYourTV & Set Native Home
```bash
./scripts/04_install_launcher.sh <FIRE_TV_IP>
```

### 6. Neutralize Hotstar Kiwi DRM (Optional)
If running Hotstar without an Amazon account login:
```bash
./scripts/05_patch_hotstar.sh <FIRE_TV_IP>
```

### 7. Block Updates
```bash
./scripts/06_block_ota.sh <FIRE_TV_IP>
```

---

## Rollback to Stock

To re-enable `com.amazon.tv.launcher`, restore default Amazon home services, and reset DNS:
```bash
./scripts/restore.sh <FIRE_TV_IP> profiles/sheldon_lite_fireos7.txt
```

---

## Credits & Upstream

- [GhostLock](https://github.com/R0rt1z2/GhostLock) by [R0rt1z2](https://github.com/R0rt1z2) — temporary kernel root exploit targeting MediaTek Fire OS devices.
- [CleanYourTV](https://github.com/Gathin23/cleanyourtv) by [Gathin23](https://github.com/Gathin23) — minimal native TV launcher and Google TV debloat prompt.

---

## License

MIT License. See [LICENSE](LICENSE).
