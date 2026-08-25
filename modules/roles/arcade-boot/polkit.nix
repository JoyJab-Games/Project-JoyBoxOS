# The in-game shutdown/reboot buttons (game_overlay.gd ->
# GameRoster.shutdown()/reboot() -> arcade-launcher-corpo's
# rust/core/src/power.rs) just shell out to `systemctl poweroff`/
# `systemctl reboot` as gamer, same as any desktop session would.
#
# First attempt at this rule targeted org.freedesktop.login1.{power-off,
# reboot} - wrong action entirely, confirmed wrong via
# /var/log/arcade/gamescope-session.log on real hardware 2026-08-25: the
# actual denial was "Failed to start reboot.target: Access denied ...",
# systemctl's own error format for going straight through
# org.freedesktop.systemd1.Manager.StartUnit rather than through logind
# (login1.reboot is what `loginctl reboot` or a desktop session manager
# would hit - `systemctl reboot` as a non-root user doesn't go through
# logind at all). Every unit start/stop, of any unit, is gated behind one
# single action for that - org.freedesktop.systemd1.manage-units - whose
# default policy is `allow_active = auth_admin_keep`: admin auth required
# even for the active local session, no passwordless fast path the way
# login1's own actions have. That's why the buttons failed silently: no
# polkit agent exists anywhere in this kiosk session to answer that
# auth_admin_keep prompt.
#
# Match on the specific target unit (via action.lookup("unit"), the
# detail systemd attaches to this check) rather than granting gamer
# manage-units wholesale - this is the one polkit action that gates
# starting/stopping *every* systemd unit, so an unscoped YES here would
# let gamer stop/restart arbitrary services, not just reboot the box.
{ ... }:
{
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user == "gamer" &&
          action.id == "org.freedesktop.systemd1.manage-units" &&
          (action.lookup("unit") == "reboot.target" ||
           action.lookup("unit") == "poweroff.target")) {
        return polkit.Result.YES;
      }
    });
  '';
}
