{ pkgs, config, lib, ... }:
let
  launchGamescope = pkgs.writeShellScriptBin "launch-gamescope" ''
      ${pkgs.gamescope}/bin/gamescope -W 1920 -H 1080 -f -e -- ${pkgs.steam}/bin/steam -gamepadui
    '';

  gamescopeSession = (pkgs.writeTextDir "share/wayland-sessions/gamescope.desktop" ''
      [Desktop Entry]
      Name=Gamescope
      Comment=Steam Big Picture Mode
      Exec=${launchGamescope}/bin/launch-gamescope
      Type=Application
    '').overrideAttrs (_: {
      passthru.providedSessions = [ "gamescope" ];
    });
in {
  options.profiles.arcadeMode.enable = lib.mkEnableOption "SteamOS Arcade Mode";

  config = lib.mkIf config.profiles.arcadeMode.enable {

    users.users.gamer = {
      isNormalUser = true;
      extraGroups = [ "video" "render" ];
      description = "Arcade Mode";
    };

    nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "steam"
      "steam-unwrapped"
    ];

    programs.steam = {
      enable = true;
      gamescopeSession.enable = true;
    };
    programs.gamescope = { enable = true; capSysNice = true; };
    programs.gamemode.enable = true;

    services.getty.autologinUser = "gamer";

    services.greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "${launchGamescope}/bin/launch-gamescope";
          user = "gamer";
        };
        default_session = {
          command = "${pkgs.greetd.regreet}/bin/regreet";
          user = "greeter";
        };
      };
    };
    programs.regreet.enable = true;

    services.displayManager.sessionPackages = [ gamescopeSession ];
  };
}