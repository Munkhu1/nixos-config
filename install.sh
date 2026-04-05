#!/usr/bin/env bash
set -e

REPO_URL="https://github.com/Munkhu1/nixos-config.git"

echo "nay nigger nay what?"

if [ "$EUID" -ne 0 ]; then
  echo "run with sudo?"
  exit 1
fi

if [ ! -d "/sys/firmware/efi/efivars" ]; then
  echo "boot in UEFI mode first gang."
  exit 1
fi

MODE=""
if [ "$#" -eq 1 ]; then
  TARGET=$1
  if [ ! -b "$TARGET" ]; then echo "$TARGET ain't valid."; exit 1; fi

  TYPE=$(lsblk -nd -o TYPE "$TARGET" 2>/dev/null || true)
  if [ "$TYPE" == "part" ]; then
    echo "You provided a single PARTITION instead of a whole drive. u slow?"
    echo "If ur trynna to dual-boot, you must provide TWO partitions: <EFI_PART> and <ROOT_PART>."
    exit 1
  fi

  MODE="DISK"

elif [ "$#" -eq 2 ]; then
  EFI_PART=$1
  ROOT_PART=$2
  if [ ! -b "$EFI_PART" ] || [ ! -b "$ROOT_PART" ]; then
    echo "One or both potatoes (partitions) don't exist."; exit 1;
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
  echo "Available block devices:"
  lsblk -dpno NAME,SIZE,TYPE,MODEL | grep -v loop
  exit 1
fi

umount -R /mnt 2>/dev/null || true
swapoff -a 2>/dev/null || true

if [ "$MODE" == "DISK" ]; then
  echo "format deez? $TARGET"
  read -p "you sure lil bro? if so, type BLACK. itged shadi: " confirm
  if [ "$confirm" != "BLACK" ]; then echo "tf?."; exit 1; fi

  echo "Partitioning $TARGET..."
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

  echo "deleting ur shit"
  mkfs.fat -F 32 -n boot "$FINAL_EFI"
  mkfs.btrfs -f -L nixos "$FINAL_ROOT"

elif [ "$MODE" == "PARTITION" ]; then
  echo "$ROOT_PART will be wiped btw. just sayin."
  echo "Your EFI partition ($EFI_PART) will be used for boot but won't be erased so u chillin."
  read -p "u sure? if so, type: JEW: " confirm
  if [ "$confirm" != "JEW" ]; then echo "Aborted."; exit 1; fi

  FINAL_EFI=$EFI_PART
  FINAL_ROOT=$ROOT_PART

  echo "shitting on $FINAL_ROOT till it becomes BTRFS"
  mkfs.btrfs -f -L nixos "$FINAL_ROOT"
fi

echo "making lil childs"
mount -t btrfs "$FINAL_ROOT" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@nix
umount /mnt

echo "mounting"
mount -o compress=zstd,subvol=@ "$FINAL_ROOT" /mnt
mkdir -p /mnt/{home,nix,boot/efi}
mount -o compress=zstd,subvol=@home "$FINAL_ROOT" /mnt/home
mount -o compress=zstd,noatime,subvol=@nix "$FINAL_ROOT" /mnt/nix
mount "$FINAL_EFI" /mnt/boot/efi

echo "cloning"
mkdir -p /mnt/etc/nixos
git clone "$REPO_URL" /mnt/etc/nixos

echo "generating ur potato config"
nixos-generate-config --root /mnt

echo "choose ur potato gpu"
echo "1) AMD Desktop/Laptop"
echo "2) Nvidia Desktop"
echo "3) Nvidia Laptop (Intel + Nvidia Optimus)"
echo "4) don't do it. trust."
read -p "Type 1, 2 or 3. not 4.: " GPU_CHOICE

LOCAL_HW_CONTENT="{ imports = [ ]; }"

case $GPU_CHOICE in
  1)
    LOCAL_HW_CONTENT="{ imports =[ ./hardware-profiles/amd-desktop.nix ]; }"
    ;;
  2)
    LOCAL_HW_CONTENT="{ imports =[ ./hardware-profiles/nvidia-desktop.nix ]; }"
    ;;
  3)
    echo "lie detecting..."

    mapfile -t GPU_LIST < <(lspci | grep -iE 'VGA|3D')

    if [ ${#GPU_LIST[@]} -eq 0 ]; then
    echo "No GPUs found? Falling back to defaults."
    LOCAL_HW_CONTENT="{ imports =[ ./hardware-profiles/nvidia-laptop-intel.nix ]; }"
    else
    echo "--------------------------------------------------------"
    for i in "${!GPU_LIST[@]}"; do
        echo "$((i+1))) ${GPU_LIST[$i]}"
    done
    echo "--------------------------------------------------------"

    read -p "which one's INTEL (iGPU)?: " igpu_num
    read -p "which one's NVIDIA (dGPU): " dgpu_num

    # raw PCI ID strings (0000:00:02.0 or 00:02.0)
    INTEL_RAW=$(echo "${GPU_LIST[$((igpu_num-1))]}" | awk '{print $1}')
    NVIDIA_RAW=$(echo "${GPU_LIST[$((dgpu_num-1))]}" | awk '{print $1}')

    to_nix_pci() {
        local pci="$1"
        if [[ "$pci" == *":"*":"* ]]; then
        pci=$(echo "$pci" | cut -d: -f2,3)
        fi

        local bus=$(echo "$pci" | cut -d: -f1)
        local dev=$(echo "$pci" | cut -d: -f2 | cut -d. -f1)
        local func=$(echo "$pci" | cut -d. -f2)

        printf "PCI:%d:%d:%d" "$((16#$bus))" "$((16#$dev))" "$((16#$func))"
    }

    INTEL_NIX=$(to_nix_pci "$INTEL_RAW")
    NVIDIA_NIX=$(to_nix_pci "$NVIDIA_RAW")

    echo "Bus IDs -> Intel: $INTEL_NIX | Nvidia: $NVIDIA_NIX"

    LOCAL_HW_CONTENT="{
imports = [ ./hardware-profiles/nvidia-laptop-intel.nix ];
hardware.nvidia.prime.intelBusId = \"$INTEL_NIX\";
hardware.nvidia.prime.nvidiaBusId = \"$NVIDIA_NIX\";
}"
    fi
    ;;
  *)
    echo "you fucking dumbass"
    ;;
esac

echo "$LOCAL_HW_CONTENT" > /mnt/etc/nixos/local-hardware.nix

echo "staging"
cd /mnt/etc/nixos
git config --global --add safe.directory /mnt/etc/nixos

git config pull.rebase true
git config rebase.autoStash true

git add -f hardware-configuration.nix local-hardware.nix
git add .

git config user.name "Munkhu"
git config user.email "munkhu@munkhus.org"
git commit -m "hardware config" || true

echo "building"
nixos-install --root /mnt --flake /mnt/etc/nixos#nixos --impure --no-root-passwd \
  --option extra-substituters "https://attic.xuyh0120.win/lantian https://cache.garnix.io https://nix-community.cachix.org" \
  --option extra-trusted-public-keys "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc= cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="

echo "permisioh"
nixos-enter --root /mnt -c "chown -R niri-dank:main /etc/nixos"
nixos-enter --root /mnt -c "chmod -R 2775 /etc/nixos"

echo "bolchloshd damn"
echo "reboot YBJN"
