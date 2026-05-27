# Gentoo-x86-easy-edition

A basic, automated bash script designed to streamline and accelerate the installation of Gentoo Linux on 32-Bit (x86/i686) systems using a classic BIOS (MBR) setup. 

The script is already pre-installed and embedded directly into the custom Live ISO.

⚠️ **WARNING:** This script is destructive. It will completely wipe the target disk you select. Use with extreme caution!

---

## Features

* **Automated MBR Partitioning:** Automatically sets up a standard DOS partition table on your target drive.
* **Latest Stage3:** Dynamically fetches and extracts the latest official `i686-openrc` Stage3 tarball.
* **Pre-configured Chroot:** Handles the heavy lifting of mounting necessary API filesystems (`/proc`, `/sys`, `/dev`, `/run`).
* **Kernel & Firmware:** Installs `gentoo-kernel-bin` for a fast build time, along with basic Linux firmware.
* **Bootloader:** Installs and configures GRUB for older BIOS/Legacy boot systems.
* **Network & Tools:** Installs and activates essential services like `dhcpcd`, `sysklogd`, and `cronie`.

---

## How to Use

1. Boot your target 32-bit x86 machine using the compiled Live ISO (ensure an active internet connection).
2. Once the system has booted and you are at the root prompt, simply run the pre-embedded script:
   ```bash
   ./gentooinstall.sh
