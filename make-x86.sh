#!/usr/bin/env bash
set -e

echo "[+] Lade aktuelle Gentoo Minimal ISO (x86 32-Bit) herunter..."
wget -O gentoo-minimal-x86.iso "https://distfiles.gentoo.org/releases/x86/autobuilds/current-install-x86-minimal/install-x86-minimal-20260505T170108Z.iso"

echo "[+] Extrahiere nur das originale SquashFS aus der ISO..."
xorriso -osirrox on -indev gentoo-minimal-x86.iso -extract /image.squashfs /tmp/image.squashfs

echo "[+] Entpacke das SquashFS (mit sudo für saubere Device Nodes)..."
# Dank sudo werden /dev/console und /dev/null korrekt erstellt, statt Fehler zu werfen
sudo unsquashfs -d /tmp/squashfs-root /tmp/image.squashfs

echo "[+] Injiziere den Installer..."
sudo cp "$GITHUB_WORKSPACE/gentooinstall.sh" /tmp/squashfs-root/root/
sudo chmod +x /tmp/squashfs-root/root/gentooinstall.sh

# Zuverlässiges Anhängen an die .bashrc als root
echo "echo 'Tippe ./gentooinstall.sh ein, um die Installation zu starten!'" | sudo tee -a /tmp/squashfs-root/root/.bashrc > /dev/null

echo "[+] Packe das SquashFS wieder zusammen..."
sudo mksquashfs /tmp/squashfs-root /tmp/new_image.squashfs -comp xz

echo "[+] Erstelle die neue, bootfähige ISO via xorriso replay..."
# Wir nehmen die originale ISO, löschen das alte SquashFS auf dem Image,
# mappen das neue rein und clonen den originalen GRUB2-Bootloader exakt.
xorriso -indev gentoo-minimal-x86.iso \
  -outdev "$GITHUB_WORKSPACE/minimal-gentoo-with-installer-x86.iso" \
  -rm /image.squashfs -- \
  -map /tmp/new_image.squashfs /image.squashfs \
  -boot_image any replay

echo "[+] Räume temporäre Sudo-Dateien auf..."
sudo rm -rf /tmp/squashfs-root /tmp/image.squashfs /tmp/new_image.squashfs

echo "[+] Fertig! Die hybride, bootfähige x86 ISO wurde erfolgreich erstellt."
