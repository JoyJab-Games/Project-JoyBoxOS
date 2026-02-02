#!/usr/bin/env bash

# Function to fetch and select from flake attributes
# Usage: select_flake_attr <REPO_URL> <ATTR_PATH (e.g. nixosConfigurations)>
select_flake_attr() {
    local REPO=$1
    local ATTR=$2

    echo "🔍 Scanning $ATTR..." >&2

    # We use 'builtins.attrNames' to force Nix to list the keys (geekom-a6, etc.)
    local OPTIONS
    OPTIONS=$(nix eval "$REPO#$ATTR" \
        --apply "builtins.attrNames" \
        --json \
        --extra-experimental-features "nix-command flakes" \
        --no-write-lock-file | jq -r '.[]')

    if [ -z "$OPTIONS" ] || [ "$OPTIONS" == "null" ]; then
        echo "❌ Error: Could not find any keys in $ATTR. Check your flake.nix!" >&2
        exit 1
    fi

    local PS3="Select $ATTR: "
    select OPT in $OPTIONS; do
        if [ -n "$OPT" ]; then
            echo "$OPT"
            return 0
        fi
    done
}
