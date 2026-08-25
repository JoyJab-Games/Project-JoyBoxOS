# The in-game shutdown/reboot buttons (game_overlay.gd ->
# GameRoster.shutdown()/reboot() -> arcade-launcher-corpo's
# rust/core/src/power.rs) just shell out to `systemctl poweroff`/
# `systemctl reboot` as gamer, same as any desktop session would. That
# normally needs no polkit rule at all: upstream's org.freedesktop.login1
# policy grants power-off/reboot to whichever session polkit considers
# "active" on its seat, no group membership required.
#
# That default silently depends on polkit seeing gamer's session as
# active, which doesn't reliably hold here - this boots straight into
# gamescope's embedded DRM/KMS mode via greetd's initial_session (see
# ./gamescope-session.nix), with no display manager and no seatd in the
# loop, unlike the desktop-session setups that default policy was written
# for. Confirmed on real hardware 2026-08-25: `sudo -u gamer systemctl
# reboot` while SSH'd in as admin hit polkit's
# org.freedesktop.login1.reboot-multiple-sessions action and prompted for
# authentication instead of the "yes, active session" fast path - and
# the actual in-game call has no polkit agent anywhere to answer that
# prompt, so it just fails closed instantly with no visible error,
# which is exactly "the buttons don't do anything".
#
# Grant gamer these two actions (and their *-multiple-sessions variants,
# which is what actually fires whenever an admin is SSH'd in
# concurrently) unconditionally instead, so the buttons don't depend on
# that active-session detection working at all.
{ ... }:
{
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "gamer" &&
          (action.id == "org.freedesktop.login1.power-off" ||
           action.id == "org.freedesktop.login1.power-off-multiple-sessions" ||
           action.id == "org.freedesktop.login1.reboot" ||
           action.id == "org.freedesktop.login1.reboot-multiple-sessions")) {
        return polkit.Result.YES;
      }
    });
  '';
}
