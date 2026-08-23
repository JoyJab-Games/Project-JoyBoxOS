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
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.gamescope arcadeLauncherPkg ]}
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
    settings.default_session = {
      command = "${gamescopeSession}/bin/arcade-gamescope-session";
      user = "gamer";
    };
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

  environment.systemPackages = [
    # For SSH admin access (see ./admin.nix) - `arcade install`/`update`/
    # `release`/`select`/etc., same commands documented throughout
    # arcade-launcher-corpo.
    arcadeCliPkg
    pkgs.steamcmd
  ];
}
