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

# TEMPORARY diagnostic logging (2026-08-25, real-hardware bring-up):
# initial_session's stdout/stderr goes straight to the physical console
# (tty1), not journald - it's gone the moment the VT switches away, and
# unreadable if nobody's physically at the machine when it happens. Mirror
# everything into a persistent file instead, so a boot attempt can be
# inspected over SSH after the fact. /var/log/arcade (not
# $XDG_RUNTIME_DIR, which is torn down when the session ends) - directory
# created via systemd.tmpfiles in gamescope-session.nix. Remove once the
# black-screen root cause is confirmed and fixed.
log="/var/log/arcade/gamescope-session.log"
exec > >(exec tee -a "$log") 2>&1
echo "==== $(date -Is) arcade-gamescope-session starting (pid $$) ===="
echo "--- env ---"
env
echo "--- DRM connector status ---"
for c in /sys/class/drm/*/status; do
  printf '%s: %s\n' "$c" "$(cat "$c" 2>/dev/null || echo '?')"
done

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
trap 'echo "$(date -Is) EXIT trap: killing gamescope pid $gamescope_pid"; kill "$gamescope_pid" 2>/dev/null || true' EXIT

if ! read -r -t 10 display wayland_display <"$socket"; then
  echo "$(date -Is) arcade-gamescope-session: gamescope didn't signal readiness in time" >&2
  exit 1
fi
echo "$(date -Is) gamescope signaled readiness: DISPLAY=$display WAYLAND_DISPLAY=$wayland_display"

# Both exported, not just one: lets arcade-launcher (Godot) connect via
# whichever backend it ends up choosing - its own gamescope integration
# makes an independent X11 connection to gamescope's Xwayland regardless
# of which one Godot itself renders through (see
# gamescope-x11-client::discover_gamescope_displays, which scans for
# gamescope Xwaylands directly rather than relying on $DISPLAY).
export DISPLAY="$display"
export WAYLAND_DISPLAY="$wayland_display"

# `if`-guarded rather than a bare call: under `set -e`, an unguarded
# nonzero exit here would jump straight to the EXIT trap and skip the
# status logging below entirely - a command directly in an `if`
# condition is exempt from -e.
if arcade-launcher; then
  launcher_status=0
else
  launcher_status=$?
fi
echo "$(date -Is) arcade-launcher exited with status $launcher_status"
if kill -0 "$gamescope_pid" 2>/dev/null; then
  echo "$(date -Is) gamescope (pid $gamescope_pid) still alive after launcher exit"
else
  echo "$(date -Is) gamescope (pid $gamescope_pid) had already exited before launcher did"
fi

kill "$gamescope_pid" 2>/dev/null || true
wait "$gamescope_pid" 2>/dev/null || true
echo "$(date -Is) arcade-gamescope-session finished"
