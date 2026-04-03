#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/Munkhu1/nixos-config.git"

echo "🚀 Starting Dank-OS Smart Installer..."

# 1. Root & UEFI Checks
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script with sudo."
  exit 1
fi

if [ ! -d "/sys/firmware/efi/efivars" ]; then
  echo "❌ This script requires the system to be booted in UEFI mode."
  exit 1
fi

# 2. Determine Mode based on arguments
MODE=""
if [ "$#" -eq 1 ]; then
  TARGET=$1
  if [ ! -b "$TARGET" ]; then echo "❌ $TARGET is not a valid block device."; exit 1; fi

  # Check if it's a disk or partition
  TYPE=$(lsblk -nd -o TYPE "$TARGET" 2>/dev/null || true)
  if [ "$TYPE" == "part" ]; then
    echo "❌ You provided a single PARTITION instead of a whole drive."
    echo "If you want to dual-boot, you must provide TWO partitions: <EFI_PART> and <ROOT_PART>."
    exit 1
  fi

  MODE="DISK"

elif [ "$#" -eq 2 ]; then
  EFI_PART=$1
  ROOT_PART=$2
  if [ ! -b "$EFI_PART" ] || [ ! -b "$ROOT_PART" ]; then
    echo "❌ One or both partitions do not exist!"; exit 1;
  fi
  MODE="PARTITION"
else
  echo "❌ Invalid usage."
  echo "--------------------------------------------------------"
  echo "Option 1: Whole Disk Wipe (1 Argument)"
  echo "  Usage: sudo ./install.sh <DRIVE>"
  echo "  Example: sudo ./install.sh /dev/nvme0n1"
  echo "--------------------------------------------------------"
  echo "Option 2: Partition/Dual-Boot Install (2 Arguments)"
  echo "  Usage: sudo ./install.sh <EFI_PART> <ROOT_PART>"
  echo "  Example: sudo ./install.sh /dev/nvme0n1p1 /dev/nvme0n1p3"
  echo "--------------------------------------------------------"
  echo "Available Block Devices:"
  lsblk -dpno NAME,SIZE,TYPE,MODEL | grep -v loop
  exit 1
fi

# Unmount anything currently active
umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

# 3. Execution Block
if [ "$MODE" == "DISK" ]; then
  echo "⚠️  WARNING: THIS WILL COMPLETELY ERASE EVERYTHING ON $TARGET! ⚠️"
  read -p "Are you absolutely sure? (Type 'YES' to confirm): " confirm
  if [ "$confirm" != "YES" ]; then echo "Aborted."; exit 1; fi

  echo "💽 Partitioning $TARGET..."
  wipefs -af "$TARGET"
  sgdisk -Z "$TARGET"
  sgdisk -n 1:0:+1G -t 1:ef00 -c 1:"EFI" "$TARGET"
  sgdisk -n 2:0:0     -t 2:8300 -c 2:"NixOS" "$TARGET"

  if [[ "$TARGET" == *"nvme"* ]] || [[ "$TARGET" == *"mmcblk"* ]]; then
    FINAL_EFI="${TARGET}p1"
    FINAL_ROOT="${TARGET}p2"
  else
    FINAL_EFI="${TARGET}1"
    FINAL_ROOT="${TARGET}2"
  fi

  echo "🧹 Formatting partitions..."
  mkfs.fat -F 3 -n boot "$FINAL_EFI"
  mkfs.btrfs -f -L nixos "$FINAL_ROOT"

elif [ "$MODE" == "PARTITION" ]; then
  echo "⚠️  WARNING: THIS WILL ERASE EVERYTHING ON $ROOT_PART! ⚠️"
  echo "ℹ️  Your EFI partition ($EFI_PART) will be used for boot but WILL NOT be erased."
  read -p "Are you absolutely sure? (Type 'YES' to confirm): " confirm
  if [ "$confirm" != "YES" ]; then echo "Aborted."; exit 1; fi

  FINAL_EFI=$EFI_PART
  FINAL_ROOT=$ROOT_PART

  echo "🧹 Formatting $FINAL_ROOT as BTRFS..."
  mkfs.btrfs -f -L nixos "$FINAL_ROOT"
fi

# 4. Common BTRFS Subvolume & Mounting Logic
echo "📁 Creating BTRFS subvolumes..."
mount -t btrfs "$FINAL_ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

echo "🔗 Mounting filesystems..."
mount -o compress=zstd,subvol=@ "$FINAL_ROOT" /mnt
mkdir -p /mnt/{home,nix,boot/efi}
mount -o compress=zstd,subvol=@home "$FINAL_ROOT" /mnt/home
mount -o compress=zstd,noatime,subvol=@nix "$FINAL_ROOT" /mnt/nix
mount "$FINAL_EFI" /mnt/boot/efi

# 5. Configuration & NixOS Install
echo "📥 Cloning your configuration repo..."
mkdir -p /mnt/etc/nixos
git clone "$REPO_URL" /mnt/etc/nixos

echo "⚙️ Generating hardware configuration..."
nixos-generate-config --root /mnt

echo "📂 Staging files for Nix Flakes..."
cd /mnt/etc/nixos
git config --global --add safe.directory /mnt/etc/nixos
git add -f hardware-configuration.nix
git config user.name "Dank-OS Installer"
git config user.email "installer@dank.os"
git commit -m "chore: local hardware configuration for new machine" || true

echo "🔨 Building NixOS (this will take a while)..."
nixos-install --root /mnt --flake /mnt/etc/nixos#nixos --impure --no-root-passwd

echo "🔐 Setting group permissions..."
chown -R root:main /mnt/etc/nixos
chmod -R 2775 /mnt/etc/nixos

echo "✅ Installation complete!"
echo "You can now type 'reboot' to boot into your new system."
