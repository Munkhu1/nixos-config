#!/usr/bin/env bash
set -e

# Replace this with your actual GitHub repo URL!
REPO_URL="https://github.com/Munkhu1/nixos-config.git"

echo "🚀 Starting Dank-OS Installation..."

# 1. Check if it's run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script with sudo."
  exit 1
fi

# 2. Back up existing config just in case
if [ -d "/etc/nixos" ] && [ ! -d "/etc/nixos/.git" ]; then
    echo "📦 Backing up existing /etc/nixos to /etc/nixos.bak..."
    mv /etc/nixos /etc/nixos.bak
fi

# 3. Clone the repository into /etc/nixos
if [ ! -d "/etc/nixos/.git" ]; then
    echo "📥 Cloning repository..."
    # We use nix-shell to ensure git is available even on a fresh install
    nix-shell -p git --run "git clone $REPO_URL /etc/nixos"
else
    echo "🔄 Repository already exists at /etc/nixos. Pulling latest changes..."
    cd /etc/nixos && git pull
fi

# 4. Generate the friend's specific hardware configuration
echo "⚙️ Generating hardware configuration for this machine..."
nixos-generate-config --dir /etc/nixos

# 5. Build the system
echo "🔨 Building NixOS (this might take a while)..."
cd /etc/nixos
# We use --impure so it can read the untracked /etc/nixos/hardware-configuration.nix
nixos-rebuild switch --flake .#nixos --impure

chown -R niri-dank:users /etc/nixos

echo "✅ Installation complete! Reboot or log out to enter your new system."
