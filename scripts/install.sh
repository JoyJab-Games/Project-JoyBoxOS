#!/usr/bin/env bash
set -e

# --- CONFIGURATION ---
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")
FLAKE_URI="path:$REPO_ROOT"
HOSTNAME=$(hostname)

echo "🚀 Starting automated NixOS installation..."

source "$SCRIPT_DIR/select-nix-config.sh"
SELECTED_CONFIG=$(select_flake_attr "$FLAKE_URI" "nixosConfigurations")
TARGET_DISK=$(nix eval --raw "$FLAKE_URI"#nixosConfigurations."$SELECTED_CONFIG".config.disko.devices.disk.main.device --extra-experimental-features "nix-command flakes")
if [[ -z "$TARGET_DISK" ]]; then
    echo "Error: Could not find disko device for '$FLAKE_URI' in the Flake."
    exit 1
fi

echo ""
read -p "🚀 Wipe $TARGET_DISK and install NixOS? (y/N): " -r confirmation

case "${confirmation,,}" in
    y|yes)
        echo "Proceeding..."
        ;;
    *)
        echo "Deployment of $SELECTED_CONFIG aborted."
        exit 1
        ;;
esac

echo "💾 Partitioning $TARGET_DISK with Disko..."
sudo nix --extra-experimental-features "nix-command flakes" \
    run github:nix-community/disko -- \
    --mode disko \
    --flake "$FLAKE_URI#$SELECTED_CONFIG" \


echo "❄️ Installing NixOS..."
sudo nixos-install --root /mnt --flake "$FLAKE_URI#$SELECTED_CONFIG" --no-root-passwd

echo "🚚 Copying configuration to /etc/nixos..."
sudo mkdir -p /mnt/etc/nixos
sudo cp -r "$REPO_ROOT/." /mnt/etc/nixos/

# this is intended for future git pulls, but since we dont know the user we should not expect this
#echo "🔑 Setting permissions for user (UID 1000)..."
#chown -R 1000:100 /mnt/etc/nixos

echo "✅ Done! You can now reboot into your new JoyBoxOS system."