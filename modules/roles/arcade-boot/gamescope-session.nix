# Boots straight into arcade-launcher-corpo under gamescope (embedded
# mode - direct DRM/KMS, no parent compositor, no Jovian). Deliberately
# NOT the real Steam client / Jovian's jovian.steam module: players should
# never see Steam's own UI, this launcher replaces it entirely.
#
# Architecture note (don't re-litigate without reading the reasoning
# first — see arcade-launcher-corpo's docs/TODO-arcade-os-session.md and
# its memory entries "gamescope-compositor-choice" /
# "arcade-os-gamescope-session-todo"): gamescope was chosen specifically
# because it's a real multi-client compositor that can host both this
# launcher and a running game, switching focus between them via its
# GAMESCOPECTRL_BASELAYER_APPID X11-atom protocol (see
# arcade-launcher-corpo's rust/core/src/gamescope.rs) - a single-client
# kiosk compositor like cage structurally can't do that. This mirrors
# OpenGamepadUI's own proven setup (also a Godot 4 gamepad-native
# launcher) via ChimeraOS's gamescope-session, simplified for this
# cabinet's fixed hardware - see gamescope-session.sh's own comments for
# what was dropped and why.
{ pkgs, lib, arcade-launcher, ... }:

let
  arcadeLauncherPkg = arcade-launcher.packages.${pkgs.system}.default;
  arcadeCliPkg = arcade-launcher.packages.${pkgs.system}.arcade-cli;

  # gamescope-session.sh already has its own real shebang (kept as a
  # genuinely standalone, directly-runnable script, not embedded Nix
  # string data) - plain install+wrap rather than writeShellApplication,
  # which would double up its own shebang/set -euo pipefail on top.
  gamescopeSession = pkgs.stdenvNoCC.mkDerivation {
    pname = "arcade-gamescope-session";
    version = "0.1.0";
    src = ./gamescope-session.sh;
    dontUnpack = true;
    nativeBuildInputs = [ pkgs.makeWrapper ];
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/arcade-gamescope-session"
      wrapProgram "$out/bin/arcade-gamescope-session" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gamescope arcadeLauncherPkg pkgs.steam-run ]}
      runHook postInstall
    '';
  };
in
{
  users.users.gamer = {
    isNormalUser = true;
    initialPassword = "gamer";
    extraGroups = [ "video" "render" "input" "networkmanager" "libvirtd" "wheel" ];
    description = "Arcade Mode";
  };

  services.greetd = {
    enable = true;
    # initial_session, not default_session: default_session is greetd's
    # slot for a real *greeter* (a program that speaks greetd's IPC
    # protocol to prompt for credentials and then request a session) -
    # pointing it straight at this plain script makes greetd treat every
    # exit as a crashed greeter ("greeter exited without creating a
    # session"), retry, and eventually hit its restart-rate-limit and
    # give up for good. initial_session is the actual no-greeter
    # autologin mechanism: it runs this command directly as `user` on
    # first VT activation, no IPC handshake required.
    settings.initial_session = {
      command = "${gamescopeSession}/bin/arcade-gamescope-session";
      user = "gamer";
    };
    # greetd itself (not just the NixOS module) hard-requires
    # default_session to have a command - it refuses to start at all
    # ("default_session contains no command") if it's absent, regardless
    # of initial_session being set. This is agreety (greetd's own bundled
    # minimal text greeter, running as the module-provided "greeter"
    # user), used only as the fallback if initial_session ever exits -
    # gives an admin a real login prompt on the physical screen to
    # recover from, rather than a permanently black one.
    settings.default_session = {
      command = "${pkgs.greetd}/bin/agreety --cmd bash";
      user = "greeter";
    };
    # No explicit `restart` needed: the module already defaults it to
    # `!(cfg.settings ? initial_session)`, i.e. false as soon as
    # initial_session is set - confirmed by reading the pinned nixpkgs
    # module source directly rather than assuming. Left unset
    # deliberately so it keeps tracking that default instead of drifting
    # from it.
  };

  # steamcmd (arcade install/update's real Steam depot downloads) is
  # unfree-licensed - same as arcade-launcher-corpo's own flake, see its
  # nixos/default.nix comment. steam-unwrapped/steam-run are pulled in
  # transitively by pkgs.gamescope itself (confirmed by evaluating this
  # config without them listed here - nothing in this file references the
  # real Steam client), not because Steam's own UI runs anywhere in this
  # session. umu-launcher and arcade-launcher-corpo's own packages are not
  # unfree, no predicate needed for those.
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steamcmd"
    "steam-unwrapped"
    "steam-run"
  ];

  # /var/log/arcade: destination for gamescope-session.sh's TEMPORARY
  # diagnostic log (see that file) - $XDG_RUNTIME_DIR gets torn down when
  # the session ends, so it can't be used for anything meant to survive
  # to be read over SSH afterward. Owned by gamer (the user the session
  # actually runs as), not root, so the script can write to it without
  # needing a setuid helper.
  systemd.tmpfiles.rules = [
    "d /var/log/arcade 0755 gamer users -"
  ];

  environment.systemPackages = [
    # For SSH admin access (see ./admin.nix) - `arcade install`/`update`/
    # `release`/`select`/etc., same commands documented throughout
    # arcade-launcher-corpo.
    arcadeCliPkg
    pkgs.steamcmd
    # Same pkgs.gamescope reference the wrapped session script's PATH is
    # built from (see gamescopeSession's wrapProgram above) - installing
    # it globally too means manual testing (`gamescope --steam -- ...`
    # from an admin shell) is always running the exact same store path/
    # version the real session does, not a coincidentally-similar one.
    # Before this, finding it for manual testing meant digging the store
    # path out of the wrapped script by hand.
    pkgs.gamescope
  ];
}
