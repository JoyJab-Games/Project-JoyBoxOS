#!/usr/bin/env bash
# Starts gamescope (embedded), waits for it to actually be ready, then
# runs arcade-launcher inside it.
#
# Loosely modeled on ChimeraOS's gamescope-session-plus
# (https://github.com/ChimeraOS/gamescope-session), which is the same
# mechanism gamescope-session-opengamepadui builds on for OpenGamepadUI -
# stripped way down for this cabinet's actual needs: one fixed AMD GPU,
# one fixed display, one client app, always. Dropped from the reference:
# Steam Deck/handheld-specific HDR/VRR tuning, mangoapp, ibus, Galileo
# hardware quirks, multi-output/orientation handling, the "N failures in
# 60s -> fall back to a desktop session" recovery logic. Kept: the one
# non-obvious, load-bearing part of that reference - gamescope's
# startup-socket readiness handshake (-R/-T), rather than a blind
# sleep-and-hope before handing off to the client.
#
# UNTESTED ON REAL HARDWARE as of the commit that added this file - see
# arcade-launcher-corpo's docs/TODO-arcade-os-session.md for how to test
# the gamescope integration itself (nested `gamescope -- ...` from a dev
# machine) before trusting this blind on the actual cabinet.
set -euo pipefail

tmpdir="$(mktemp -d -p "${XDG_RUNTIME_DIR:-/tmp}" gamescope.XXXXXXX)"
socket="$tmpdir/startup.socket"
stats="$tmpdir/stats.pipe"
mkfifo -- "$socket" "$stats"

# --steam: not literal Steam - this is what turns on gamescope's X11-atom
# control-protocol surface (GAMESCOPECTRL_BASELAYER_APPID, STEAM_GAME,
# etc.) that arcade-launcher's own compositor integration depends on (see
# arcade-launcher-corpo's rust/core/src/gamescope.rs). ChimeraOS's own
# session passes this unconditionally too, for the same reason, not
# because it's running real Steam.
gamescope --steam -R "$socket" -T "$stats" &
gamescope_pid=$!
trap 'kill "$gamescope_pid" 2>/dev/null || true' EXIT

if ! read -r -t 10 display wayland_display <"$socket"; then
  echo "arcade-gamescope-session: gamescope didn't signal readiness in time" >&2
  exit 1
fi

# Both exported, not just one: lets arcade-launcher (Godot) connect via
# whichever backend it ends up choosing - its own gamescope integration
# makes an independent X11 connection to gamescope's Xwayland regardless
# of which one Godot itself renders through (see
# gamescope-x11-client::discover_gamescope_displays, which scans for
# gamescope Xwaylands directly rather than relying on $DISPLAY).
export DISPLAY="$display"
export WAYLAND_DISPLAY="$wayland_display"

arcade-launcher

kill "$gamescope_pid" 2>/dev/null || true
wait "$gamescope_pid" 2>/dev/null || true
