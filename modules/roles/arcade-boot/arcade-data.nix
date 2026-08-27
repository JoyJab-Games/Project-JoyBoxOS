# Shared, fixed-path storage for arcade-launcher-corpo's installed-game
# data (see its rust/core/src/lib.rs `data_dir()`), which otherwise
# defaults to $HOME/.local/share/arcade-launcher - overridden here via
# ARCADE_DATA_DIR. This matters specifically because installing and
# actually running a game happen as two different users by design: admin
# (over SSH, see ./admin.nix) runs `arcade install`/`release`/etc., gamer
# (see ./gamescope-session.nix) runs the actual gamescope session. Without
# a shared override, each user's own $HOME-relative default put installed
# game data somewhere the other user's process never looks - confirmed to
# actually bite on real hardware 2026-08-25 (installed via SSH as admin,
# invisible to the launcher running as gamer).
{ ... }:
{
  users.groups.arcade-data = { };
  users.users.gamer.extraGroups = [ "arcade-data" ];
  users.users.admin.extraGroups = [ "arcade-data" ];

  # setgid (02775): anything arcade-cli or arcade-launcher creates under
  # here inherits the arcade-data group instead of the creating user's own
  # primary group, so a write from one user stays group-writable to the
  # other rather than quietly reintroducing the same kind of per-user
  # split this file exists to fix.
  systemd.tmpfiles.rules = [
    "d /var/lib/arcade 02775 root arcade-data -"
    "d /run/arcade-steamcmd-session 02775 root arcade-data -"
  ];

  # environment.variables (not a one-off export in gamescope-session.sh):
  # needs to reach both admin's interactive SSH shell (`arcade install`
  # run by hand) and gamer's non-interactive greetd session alike, and
  # this is the mechanism already confirmed (via gamescope-session.sh's
  # own env dump) to reach both - it's the same path NixOS's own
  # i18n/locale settings use to land in that session's environment.
  environment.variables.ARCADE_DATA_DIR = "/var/lib/arcade";

  # ARCADE_STEAMCMD_SESSION_DIR: without this, steamcmd_session_dir()
  # (rust/core/src/lib.rs) points steamcmd's $HOME at
  # $XDG_RUNTIME_DIR/arcade-launcher/steamcmd, falling back to the system
  # temp dir (/tmp/arcade-launcher/steamcmd) when $XDG_RUNTIME_DIR isn't
  # set - which it isn't for admin's `sudo -i -u gamer` (see ./admin.nix),
  # since sudo doesn't go through logind/pam_systemd. That fallback is
  # fatal, not just suboptimal: steam-run's own bwrap sandbox
  # unconditionally does `--tmpfs /tmp`, replacing the entire /tmp tree
  # with an empty tmpfs *inside* the sandbox, so steamcmd.sh - which does
  # get written to $HOME/.local/share/Steam on the real filesystem -
  # becomes invisible the moment steamcmd actually execs inside its own
  # sandbox ("No such file or directory", confirmed by reproducing the
  # exact failure with a bare `HOME=/tmp/x steamcmd` outside arcade
  # entirely 2026-08-27). gamer's own gamescope session never hits this,
  # because it has a real $XDG_RUNTIME_DIR=/run/user/<uid>, and /run is
  # bind-mounted through by steam-run rather than wiped. Fixed the same
  # way as ARCADE_DATA_DIR above: a fixed, shared, /run-backed (so still
  # tmpfs, still gone at reboot, matching the intent of the code comment
  # this overrides) path that doesn't depend on a logind session existing.
  environment.variables.ARCADE_STEAMCMD_SESSION_DIR = "/run/arcade-steamcmd-session";
}
