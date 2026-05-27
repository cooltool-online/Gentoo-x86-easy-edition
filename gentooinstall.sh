#!/usr/bin/env bash
# A basic automated Gentoo installer skeleton for x86 (32-Bit BIOS).
# WARNING: THIS WILL WIPE THE TARGET DISK. USE WITH CAUTION.

set -e # Exit immediately if a command exits with a non-zero status

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (or use sudo)."
  exit 1
fi

clear
echo "========================================"
echo "    Gentoo Install (x86 32-Bit BIOS)    "
echo "========================================"
echo ""

# --- 1. Gather User Input ---
read -p "Enter the disk to install to (e.g., /dev/sda): " TARGET_DISK
read -p "Enter your desired hostname: " SYSTEM_HOSTNAME
read -s -p "Enter the root password for the new system: " ROOT_PASSWORD
echo ""
read -p "Are you absolutely sure you want to WIPE $TARGET_DISK and install Gentoo? (y/N): " CONFIRM

if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Installation aborted."
    exit 0
fi

# Target partitions for MBR/BIOS
PART_ROOT="${TARGET_DISK}1"

# --- 2. Partitioning (BIOS / MBR Setup) ---
echo "[+] Partitioning $TARGET_DISK with MBR..."
parted -s "$TARGET_DISK" mklabel msdos
parted -s "$TARGET_DISK" mkpart primary ext4 1MiB 100%
parted -s "$TARGET_DISK" set 1 boot on

# --- 3. Formatting ---
echo "[+] Formatting root partition..."
mkfs.ext4 -F "$PART_ROOT"

# --- 4. Mounting ---
echo "[+] Mounting partitions..."
mount "$PART_ROOT" /mnt/gentoo

# --- 5. Fetching and Extracting Stage3 (OpenRC x86 / i686) ---
echo "[+] Fetching latest x86 Stage3 tarball..."
cd /mnt/gentoo
STAGE3_TXT_URL="https://distfiles.gentoo.org/releases/x86/autobuilds/latest-stage3-i686-openrc.txt"
STAGE3_PATH=$(curl -s "$STAGE3_TXT_URL" | grep -v "^#" | awk '{print $1}')
STAGE3_URL="https://distfiles.gentoo.org/releases/x86/autobuilds/$STAGE3_PATH"

wget "$STAGE3_URL"
echo "[+] Extracting Stage3 (this will take a moment)..."
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner > /dev/null

# --- 6. Base Configuration Setup ---
echo "[+] Preparing chroot environment..."
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run

# --- 7. Creating the Chroot Script ---
cat <<EOF > /mnt/gentoo/chroot-install.sh
#!/usr/bin/env bash
set -e
source /etc/profile
export PS1="(chroot) \${PS1}"

echo "[+] Syncing Portage tree..."
emerge-webrsync

echo "[+] Setting timezone to UTC..."
echo "UTC" > /etc/timezone
emerge --config sys-libs/timezone-data

echo "[+] Setting locale..."
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
eselect locale set 1

echo "[+] Setting hostname..."
echo "$SYSTEM_HOSTNAME" > /etc/hostname

echo "[+] Installing kernel (using gentoo-kernel-bin for speed)..."
emerge sys-kernel/gentoo-kernel-bin
emerge sys-kernel/linux-firmware

echo "[+] Generating fstab..."
emerge sys-fs/genfstab
genfstab -U / > /etc/fstab

echo "[+] Installing and configuring GRUB for BIOS..."
emerge sys-boot/grub
grub-install --target=i386-pc "$TARGET_DISK"
grub-mkconfig -o /boot/grub/grub.cfg

echo "[+] Installing essential tools..."
emerge app-admin/sysklogd sys-process/cronie net-misc/dhcpcd
rc-update add sysklogd default
rc-update add cronie default
rc-update add dhcpcd default

echo "[+] Setting root password..."
echo "root:$ROOT_PASSWORD" | chpasswd

echo "[+] Chroot setup complete!"
EOF

chmod +x /mnt/gentoo/chroot-install.sh

# --- 8. Executing the Chroot Script ---
echo "[+] Entering chroot to finalize installation..."
chroot /mnt/gentoo /chroot-install.sh

# --- 9. Cleanup ---
echo "[+] Cleaning up..."
rm /mnt/gentoo/chroot-install.sh
rm /mnt/gentoo/stage3-*.tar.xz

echo "=================================================================="
echo " Installation Complete! "
echo " You can now reboot your system. Don't forget to remove the USB."
echo "=================================================================="
