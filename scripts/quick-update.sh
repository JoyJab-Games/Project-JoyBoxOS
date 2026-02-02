#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
REPO_ROOT=$(realpath "$SCRIPT_DIR/..")

cd "$REPO_ROOT" || (echo "couldn't switch" && exit)
git pull
nixos-rebuild switch
