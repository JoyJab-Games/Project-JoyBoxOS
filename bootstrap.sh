#!/usr/bin/env bash
set -e

# Target repository settings
GIT_REPO="https://github.com/JoyJab-Games/arcade-os.git"
BRANCH="${1:-main}"

echo "📥 Preparing configuration directory (Branch: ${BRANCH})..."

TEMP_CLONE="/tmp/joybox-installer"
[ -d "$TEMP_CLONE" ] && sudo rm -rf "$TEMP_CLONE"

echo "📂 Cloning branch '${BRANCH}' into memory..."
git clone -b "$BRANCH" --single-branch "$GIT_REPO" "$TEMP_CLONE"

cd "$TEMP_CLONE"
chmod +x scripts/*.sh

echo "🚀 Executing installation script..."
./scripts/install.sh