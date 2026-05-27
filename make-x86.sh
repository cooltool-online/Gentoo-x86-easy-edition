#!/usr/bin/env bash
set -e

echo "[+] Lade aktuelle Gentoo Minimal ISO (x86 32-Bit) herunter..."
wget -O gentoo-minimal-x86.iso "https://distfiles.gentoo.org/releases/x86/autobuilds/current-install-x86-minimal/install-x86-minimal-20260505T170108Z.iso"

echo "[+] Entpacke die ISO..."
mkdir -p /tmp/iso-extract
xorriso -osirrox on -indev gentoo-minimal-x86.iso -extract / /tmp/iso-extract

echo "[+] Entpacke das SquashFS (Das eigentliche Live-System)..."
cd /tmp/iso-extract
unsquashfs -force -d /tmp/squashfs-root image.squashfs || true

echo "[+] Injiziere den Installer..."
# Pfad korrigiert auf das aktuelle Arbeitsverzeichnis
cp "$GITHUB_WORKSPACE/gentooinstall.sh" /tmp/squashfs-root/root/
chmod +x /tmp/squashfs-root/root/gentooinstall.sh

echo "echo 'Tippe ./gentooinstall.sh ein, um die Installation zu starten!'" >> /tmp/squashfs-root/root/.bashrc

echo "[+] Packe das SquashFS wieder zusammen..."
rm image.squashfs
mksquashfs /tmp/squashfs-root image.squashfs -comp xz

echo "[+] Erstelle die neue, bootfähige x86 ISO (Nur für klassisches BIOS)..."
# Ausgabe-Pfad angepasst, damit GitHub Actions das Artefakt direkt findet
xorriso -as mkisofs -r -J -joliet-long -l \
  -b isolinux/isolinux.bin -c isolinux/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  -o "$GITHUB_WORKSPACE/minimal-gentoo-with-installer-x86.iso" /tmp/iso-extract/

echo "[+] Fertig! Die reine BIOS-32-Bit-ISO wurde erstellt."
