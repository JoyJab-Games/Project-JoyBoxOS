#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
REPO_URL="github:JoyJab-Games/Project-JoyBoxOS"
TARGET_DISK="/dev/nvme0n1" # Or use $(lsblk -no PKNAME,TYPE | grep disk | head -n1)
HOSTNAME=$(hostname)

echo "🚀 Starting automated NixOS installation for $HOSTNAME..."


echo "🔍 Probing hardware..."
mkdir -p /tmp/nixos
nixos-generate-config --no-filesystems --dir /tmp/nixos


echo "💾 Partitioning disk with Disko..."
nix --extra-experimental-features "nix-command flakes" \
    run github:nix-community/disko -- \
    --mode disko \
    --flake "$REPO_URL#generic" \
    --arg device "\"$TARGET_DISK\""


echo "📂 Preparing /etc/nixos on target..."
mkdir -p /mnt/etc/nixos
cp /tmp/nixos/hardware-configuration.nix /mnt/etc/nixos/local-hardware.nix


echo "❄️ Installing NixOS..."
nixos-install --flake "$REPO_URL#generic" --no-root-passwd

echo "✅ Done! Reboot and remove the installer."