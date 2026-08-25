#!/usr/bin/env bash
set -e

GIT_REPO="https://github.com/JoyJab-Games/arcade-os.git"
BRANCH="$1"

# If no branch argument was passed, prompt the user interactively
if [ -z "$BRANCH" ]; then
    read -rp "Enter branch to install [default: main]: " INPUT_BRANCH
    BRANCH="${INPUT_BRANCH:-main}"
fi

echo "📥 Preparing configuration directory..."
echo "🌿 Selected Branch: ${BRANCH}"

TEMP_CLONE="/tmp/joybox-installer"
[ -d "$TEMP_CLONE" ] && sudo rm -rf "$TEMP_CLONE"

echo "📂 Cloning branch '${BRANCH}' into memory..."
git clone -b "$BRANCH" --single-branch "$GIT_REPO" "$TEMP_CLONE"

cd "$TEMP_CLONE"
chmod +x scripts/*.sh

echo "🚀 Executing installation script..."
./scripts/install.sh