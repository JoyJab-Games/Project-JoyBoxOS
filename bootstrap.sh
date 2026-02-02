#!/usr/bin/env bash
set -e

# The physical mount point for the new OS
GIT_REPO="https://github.com/JoyJab-Games/Project-JoyBoxOS.git"

echo "📥 Preparing configuration directory..."

TEMP_CLONE="/tmp/joybox-installer"
[ -d "$TEMP_CLONE" ] && sudo rm -rf "$TEMP_CLONE"

echo "📂 Cloning repo to memory..."
git clone "$GIT_REPO" "$TEMP_CLONE"

cd "$TEMP_CLONE"
chmod +x scripts/*.sh

./scripts/install.sh