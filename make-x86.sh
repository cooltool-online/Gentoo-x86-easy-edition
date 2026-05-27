#!/usr/bin/env bash
set -e

echo "[+] Lade aktuelle Gentoo Minimal ISO (x86 32-Bit) herunter..."
wget -O gentoo-minimal-x86.iso "https://distfiles.gentoo.org/releases/x86/autobuilds/current-install-x86-minimal/install-x86-minimal-20260505T170108Z.iso"

echo "[+] Extrahiere nur das SquashFS (Das eigentliche Live-System)..."
# Es reicht, nur das SquashFS zu extrahieren, nicht die ganze ISO
xorriso -osirrox on -indev gentoo-minimal-x86.iso -extract /image.squashfs /tmp/image.squashfs

echo "[+] Entpacke das SquashFS..."
unsquashfs -d /tmp/squashfs-root /tmp/image.squashfs

echo "[+] Injiziere den Installer..."
cp "$GITHUB_WORKSPACE/gentooinstall.sh" /tmp/squashfs-root/root/
chmod +x /tmp/squashfs-root/root/gentooinstall.sh

echo "echo 'Tippe ./gentooinstall.sh ein, um die Installation zu starten!'" >> /tmp/squashfs-root/root/.bashrc

echo "[+] Packe das SquashFS wieder zusammen..."
mksquashfs /tmp/squashfs-root /tmp/new_image.squashfs -comp xz

echo "[+] Erstelle die neue, bootfähige ISO..."
# Die originale ISO wird als Vorlage genutzt. Das alte SquashFS wird gelöscht,
# das neue gemappt, und alle Boot-Sektoren werden per 'replay' exakt übernommen.
xorriso -indev gentoo-minimal-x86.iso \
  -outdev "$GITHUB_WORKSPACE/minimal-gentoo-with-installer-x86.iso" \
  -rm /image.squashfs -- \
  -map /tmp/new_image.squashfs /image.squashfs \
  -boot_image any replay

echo "[+] Fertig! Die neue ISO mit intaktem Bootloader wurde erstellt."
