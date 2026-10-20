# firetv-clean-root

Native launcher replacement, system debloat, and Appstore DRM bypass for Amazon Fire TV devices using in-memory root.

[The prompt](PROMPT.md) · [Architecture](docs/ARCHITECTURE.md) · [Debloat list](profiles/sheldon_lite_fireos7.txt) · [Troubleshooting](docs/TROUBLESHOOTING.md)

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
  - Any Fire OS device compatible with [GhostLock](https://github.com/R0rt1z2/GhostLock)

---

## Quick Start (One Command)

### 1. Enable ADB on Fire TV
1. On your Fire TV, open `Settings` > `My Fire TV` > `About`.
2. Highlight your device name and click the select button 7 times to enable Developer Options.
3. Go back one screen > `Developer Options` > turn on **ADB Debugging**.

### 2. Run Setup
```bash
./clean.sh <FIRE_TV_IP>
```
*Example: `./clean.sh 192.168.1.50`*

The script executes the complete setup in one pass:
1. Connects to the Fire TV over ADB.
2. Initializes the GhostLock root daemon (`/data/local/tmp/gl/ghostlock_root`).
3. Disables 35+ Amazon telemetry, ad, and recommendation services.
4. Configures system-wide AdGuard Private DNS (`dns.adguard-dns.com`).
5. Installs the CleanYourTV native launcher and pre-compiles dex via `dex2oat`.
6. Disables `com.amazon.tv.launcher` and registers CleanYourTV as default HOME.
7. Disables Amazon OTA update services.
8. Neutralizes Hotstar Kiwi DRM account enforcement if Hotstar is detected.

Alternatively, paste [PROMPT.md](PROMPT.md) into Claude Code, Antigravity, or your AI coding assistant to run the process step by step.

---

## Reverting to Original State

To undo all modifications and bring the Fire TV back to its original state (note: this does NOT perform a factory reset; all user data, sideloaded apps, and login credentials remain completely intact):
```bash
./restore.sh <FIRE_TV_IP>
```

---

## Repository Structure

```
firetv-clean-root/
├── clean.sh                 # Single one-line setup script
├── restore.sh               # One-line rollback to original Amazon state
├── PROMPT.md                # Pasteable prompt for AI coding assistants
├── launcher/
│   └── cleanyourtv-release.apk  # Prebuilt CleanYourTV launcher binary (328 KB)
├── profiles/
│   ├── sheldon_lite_fireos7.txt # Debloat profile for Fire TV Stick Lite (Fire OS 7)
│   └── mantis_4k_fireos6.txt    # Debloat profile for Fire TV Stick 4K (Fire OS 6)
├── docs/
│   ├── ARCHITECTURE.md          # Exploit details, SELinux patching, and Home intent routing
│   ├── DEBLOAT_LISTS.md         # Full package breakdown: safe vs load-bearing
│   ├── HOTSTAR_KIWI_PATCH.md    # Smali reverse engineering and Kiwi DRM neutralization
│   └── TROUBLESHOOTING.md       # Recovery steps, ADB fixes, and rollback
├── CONTRIBUTING.md
├── LICENSE
└── README.md
```

---

## Safety Whitelist

The scripts will never touch:
- Bluetooth remote pairing and input services.
- On-screen keyboard (`com.amazon.tv.ime`).
- System settings menu (`com.amazon.tv.settings.v2`).
- User-installed IPTV credentials (`com.onnet.systems.iptv.pioneer`).

---

## Credits & Upstream

- [GhostLock](https://github.com/R0rt1z2/GhostLock) by [R0rt1z2](https://github.com/R0rt1z2) — temporary kernel root exploit targeting MediaTek Fire OS devices.
- [CleanYourTV](https://github.com/Gathin23/cleanyourtv) by [Gathin23](https://github.com/Gathin23) — minimal native TV launcher and Google TV debloat prompt.

---

## License

MIT License. See [LICENSE](LICENSE).
