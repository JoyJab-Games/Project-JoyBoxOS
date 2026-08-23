{ pkgs, config, lib, ... }:

let
  myTheme = pkgs.callPackage ./theme.nix { };
in {

  boot.plymouth = {
    enable = true;
    themePackages = [ myTheme ];
    theme = "joyjab-arcade";
  };
  boot.loader.timeout = 0;

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.kernelParams = [ "quiet" "splash" "rd.systemd.show_status=false" ];
}

