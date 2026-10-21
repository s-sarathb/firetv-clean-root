# Contributing to FireTV Clean Root

We welcome contributions from the community to expand device support, update debloat profiles, and improve launcher integration.

## How to Contribute
1. **Device Profiles:** If you test on a different Fire TV model (Cube, Omni, 4K Max), submit your profile under `profiles/<codename>_<os_version>.txt`.
2. **Safety First:** Never include load-bearing packages (`com.amazon.tv.settings.v2`, `com.amazon.tv.ime`, etc.) in debloat profiles.
3. **Shell Script Integrity:** Run `shellcheck` on all shell scripts before submitting pull requests.
4. **Documentation:** Keep reverse engineering notes and smali patch steps precise.
