# modules/plymouth/default.nix
{ pkgs, config, lib, ... }:

let
  # This calls the derivation we wrote earlier
  myTheme = pkgs.callPackage ./theme.nix { };
in {
  # This makes 'services.arcadeCustoms.plymouth' a toggleable option
  options.services.arcadeCustoms.plymouth.enable = lib.mkEnableOption "Arcade Boot Splash";

  config = lib.mkIf config.services.arcadeCustoms.plymouth.enable {
    boot.plymouth = {
      enable = true;
      themePackages = [ myTheme ];
      theme = "joyjab-arcade";
    };

    # Essential for a clean "Console-like" boot experience
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
    boot.kernelParams = [ "quiet" "splash" "rd.systemd.show_status=false" ];
  };
}

