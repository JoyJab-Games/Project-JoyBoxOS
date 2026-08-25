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
  ];

  # environment.variables (not a one-off export in gamescope-session.sh):
  # needs to reach both admin's interactive SSH shell (`arcade install`
  # run by hand) and gamer's non-interactive greetd session alike, and
  # this is the mechanism already confirmed (via gamescope-session.sh's
  # own env dump) to reach both - it's the same path NixOS's own
  # i18n/locale settings use to land in that session's environment.
  environment.variables.ARCADE_DATA_DIR = "/var/lib/arcade";
}
