#!/usr/bin/env bash
set -e

echo "[+] Lade aktuelle Gentoo Minimal ISO (x86 32-Bit) herunter..."
wget -O gentoo-minimal-x86.iso "https://distfiles.gentoo.org/releases/x86/autobuilds/current-install-x86-minimal/install-x86-minimal-20260505T170108Z.iso"

echo "[+] Entpacke die ISO..."
mkdir -p /tmp/iso-extract
xorriso -osirrox on -indev gentoo-minimal-x86.iso -extract / /tmp/iso-extract

echo "[+] Entpacke das SquashFS (Das eigentliche Live-System)..."
# Nutze sudo im GitHub-Runner, um /dev/console und /dev/null fehlerfrei zu erstellen
sudo unsquashfs -d /tmp/squashfs-root /tmp/iso-extract/image.squashfs

echo "[+] Injiziere den Installer..."
sudo cp "$GITHUB_WORKSPACE/gentooinstall.sh" /tmp/squashfs-root/root/
sudo chmod +x /tmp/squashfs-root/root/gentooinstall.sh
echo "echo 'Tippe ./gentooinstall.sh ein, um die Installation zu starten!'" | sudo tee -a /tmp/squashfs-root/root/.bashrc > /dev/null

echo "[+] Packe das SquashFS wieder zusammen..."
sudo rm -f /tmp/iso-extract/image.squashfs
sudo mksquashfs /tmp/squashfs-root /tmp/iso-extract/image.squashfs -comp xz

echo "[+] Suche GRUB2 Boot-Image für klassischen BIOS-Boot..."
# Wir suchen dynamisch nach der eltorito.img von GRUB2
BOOT_IMG=$(find /tmp/iso-extract -name "eltorito.img" -print -quit)
if [ -z "$BOOT_IMG" ]; then
    echo "[-] Fehler: eltorito.img wurde in der ISO nicht gefunden!"
    exit 1
fi

# Pfad relativ zum Extraktions-Verzeichnis umrechnen
BOOT_REL=${BOOT_IMG#/tmp/iso-extract/}
echo "[+] Gefundenes Boot-Image: $BOOT_REL"

echo "[+] Erstelle die neue, bootfähige x86 ISO (Reines MBR / Klassisches BIOS)..."
# -G extrahiert den originalen Bootcode aus dem System-Header der alten ISO (für Isohybrid/USB-Boot)
# --grub2-boot-info teilt xorriso mit, dass es sich um den GRUB-Bootloader handelt
xorriso -as mkisofs -r -J -joliet-long -l \
  -b "$BOOT_REL" -no-emul-boot -boot-load-size 4 -boot-info-table \
  --grub2-boot-info \
  -G gentoo-minimal-x86.iso \
  -o "$GITHUB_WORKSPACE/minimal-gentoo-with-installer-x86.iso" /tmp/iso-extract/

echo "[+] Räume auf..."
sudo rm -rf /tmp/squashfs-root /tmp/iso-extract

echo "[+] Fertig! Die reine BIOS-32-Bit-ISO (nur MBR) wurde erfolgreich erstellt."
