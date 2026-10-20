<h1 align="center">🔥 FireTV Clean Root</h1>

<p align="center">
  <b>True Native Launcher Replacement & Complete Debloat Toolkit for Amazon Fire TV</b><br>
  <i>No button-remapper lag · No accessibility hacks · Permanent stock launcher removal · Hotstar Kiwi DRM patch</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-Fire%20OS%207%20%7C%206-orange?style=flat-square" alt="Platform">
  <img src="https://img.shields.io/badge/Target-Fire%20TV%20Stick%20Lite%20%2F%204K%20%2F%20Max-blue?style=flat-square" alt="Target">
  <img src="https://img.shields.io/badge/Root-GhostLock%20(MediaTek)-red?style=flat-square" alt="Root">
  <img src="https://img.shields.io/badge/Launcher-CleanYourTV%20%7C%20Projectivy-green?style=flat-square" alt="Launcher">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square" alt="License">
</p>

---

## 📌 Why This Repository Exists

Amazon Fire TV devices are notorious for heavy monetization, invasive telemetry, and aggressive anti-customization protections:
* **Un-disableable Stock Launcher:** Executing `pm disable` or `pm uninstall` against `com.amazon.tv.launcher` throws `SecurityException: Cannot disable a protected package` or `DELETE_FAILED_INTERNAL_ERROR`.
* **Broken Third-Party Hacks:** Existing tools (e.g. *Launcher Manager Mini*) rely on Android `AccessibilityService` key event listeners, introducing a noticeable 500ms–1500ms delay and flickering before the launcher renders. Amazon regularly patches these via silent OTA updates.
* **Appstore DRM Locks:** Sideloaded streaming apps (like JioHotstar) query Amazon's Kiwi DRM framework via IPC; without an active Amazon login, they display a blocking modal and invoke `System.exit(0)`.

**FireTV Clean Root** provides a root-driven methodology to permanently strip Amazon telemetry, bypass `PackageManagerService` restrictions, natively bind a lightweight, ad-free launcher (such as [CleanYourTV](https://github.com/Gathin23/cleanyourtv) or [Projectivy](https://github.com/spocky/miproja1)) as the default `HOME` activity with **zero latency**, and neutralize Appstore DRM blocks.

---

## ⚡ Key Features

- **🚀 Native HOME Binding:** Zero-latency remote responsiveness using Android's native `cmd package set-home-activity`.
- **🛡️ Full System Debloat:** Disables 35+ Amazon telemetry, metrics, ad syndication, and recommendation packages.
- **🔒 Permanent OTA Neutralization:** Blocks Amazon from quietly pushing updates that overwrite your launcher settings.
- **🔓 Hotstar Kiwi DRM Bypass:** Smali bytecode patch eliminating Amazon account login requirements while keeping Widevine L1 4K hardware decoding intact.
- **🛡️ Load-Bearing Safeguards:** Hardcoded guards to protect IPTV apps (e.g. Pioneer Digital TV) and critical system services.
- **🌐 Network-Wide Ad Blocking:** Configures native AdGuard Private DNS (`dns.adguard-dns.com`) at the system level.

---

## 🏗️ Technical Architecture

```
                    [ Remote HOME Button ]
                              |
                              v  (0 ms Hardware Key Event)
                [ Android Window Manager Service ]
                              |
                              v  (Resolved Intent: CATEGORY_HOME)
               +------------------------------+
               | CleanYourTV Native Launcher  |
               | (com.gathin.tvhome)          |
               +------------------------------+
                              |
    +-------------------------+-------------------------+
    |                         |                         |
    v                         v                         v
[ Stock Launcher ]     [ Amazon Telemetry ]     [ Appstore DRM ]
(Disabled via Root)   (Disabled via Root)   (Kiwi Smali Patched)
```

For full exploit and system architecture details, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🚀 Quick Start Guide

### Prerequisites
1. **Target Device:** Amazon Fire TV Stick Lite / 4K / Max running Fire OS 7 (or Fire OS 6).
2. **Network Connection:** Computer and Fire TV Stick on the same local Wi-Fi.
3. **Developer Options:**
   - Go to `Settings` -> `My Fire TV` -> `About`.
   - Tap the device name **7 times** to unlock Developer Options.
   - Go back -> `Developer Options` -> Enable **ADB Debugging**.

---

### Step 1: Connect to Device
```bash
./scripts/01_connect_device.sh <FIRE_TV_IP>
```

### Step 2: Initialize Root (GhostLock)
```bash
./scripts/02_deploy_root.sh <FIRE_TV_IP>
```
*Verifies UID 0 root shell and switches SELinux to Permissive (`enforcing 1->0`).*

### Step 3: Strip Telemetry & Bloatware
```bash
./scripts/03_debloat_firetv.sh <FIRE_TV_IP> profiles/sheldon_lite_fireos7.txt
```
*Disables ad engines, analytics collectors, preloaded apps, and configures AdGuard Private DNS.*

### Step 4: Install Clean Launcher & Bind Default Home
```bash
# To install CleanYourTV (Apple TV-style minimal launcher):
./scripts/04_install_launcher.sh <FIRE_TV_IP> cleanyourtv

# Or to install Projectivy Launcher:
./scripts/04_install_launcher.sh <FIRE_TV_IP> projectivy
```
*Disables stock `com.amazon.tv.launcher` and registers the chosen launcher with `cmd package set-home-activity --user 0`.*

### Step 5: Neutralize Hotstar Kiwi DRM (Optional)
```bash
./scripts/05_patch_hotstar.sh <FIRE_TV_IP>
```
*Bypasses Amazon account login prompts in Hotstar without losing user data or hardware decoding.*

### Step 6: Block Amazon OTA Updates
```bash
./scripts/06_block_ota.sh <FIRE_TV_IP>
```

---

## 📁 Repository Structure & Branch Strategy

### Main Branch (`main`)
The main branch contains all source code, deployment scripts, profiles, and documentation:
```
firetv-clean-root/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
│       ├── build-launcher.yml    # Validates shell scripts & profile syntax
│       └── release.yml           # Automated release asset packaging
├── docs/
│   ├── ARCHITECTURE.md          # Technical deep-dive on Fire OS internals
│   ├── DEBLOAT_LISTS.md         # Package breakdown: Safe vs Load-Bearing
│   ├── HOTSTAR_KIWI_PATCH.md    # Kiwi DRM smali reverse engineering notes
│   └── TROUBLESHOOTING.md       # Emergency recovery & troubleshooting
├── launcher/
│   └── cleanyourtv-release.apk  # Pre-compiled lightweight launcher binary
├── profiles/
│   ├── sheldon_lite_fireos7.txt # Debloat profile for Fire TV Stick Lite / 3rd Gen
│   └── mantis_4k_fireos6.txt    # Debloat profile for Fire TV Stick 4K 1st Gen
├── scripts/
│   ├── 01_connect_device.sh     # ADB discovery & connection
│   ├── 02_deploy_root.sh        # GhostLock daemon deployment
│   ├── 03_debloat_firetv.sh     # Root-enforced package debloater
│   ├── 04_install_launcher.sh   # Launcher installer & native Home binder
│   ├── 05_patch_hotstar.sh      # Automated Kiwi DRM patcher
│   ├── 06_block_ota.sh          # Permanent OTA updater blocker
│   └── restore.sh               # Complete rollback script
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

### 🏷️ Release & Tag Strategy
* **Tags:** Follow Semantic Versioning (`v1.0.0`, `v1.1.0`).
* **Release Assets (`.tar.gz`):**
  - Complete standalone bundle containing `scripts/`, `profiles/`, and `docs/`.
  - Precompiled `cleanyourtv-release.apk` (328 KB) attached directly to the GitHub Release.
  - Checksums (`SHA256SUMS.txt`) for all binary artifacts.

---

## 🔄 Reverting to Stock
To undo all modifications and restore the original Amazon stock launcher:
```bash
./scripts/restore.sh <FIRE_TV_IP> profiles/sheldon_lite_fireos7.txt
```

---

## ⚖️ Disclaimer & License
This project is for educational and research purposes. Modifying system packages requires root access and carries inherent risks. The maintainers are not responsible for bricked devices or warranty voiding.

Licensed under the [MIT License](LICENSE).
