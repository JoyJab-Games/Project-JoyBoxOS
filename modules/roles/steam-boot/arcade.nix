{ pkgs, config, lib, jovian, ... }:

{
  imports = [
    jovian.nixosModules.default
  ];

  jovian = {
    steam = {
      enable = true;
      autoStart = true;
      user = "gamer";
      desktopSession = "gamescope-wayland";
    };
    devices.steamdeck.enable = false;
    hardware.has.amd.gpu = true;
  };

  users.users.gamer = {
    isNormalUser = true;
    initialPassword = "gamer";
    extraGroups = [ "video" "render" "input" "networkmanager" "libvirtd" "wheel" ];
    description = "Arcade Mode";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-unwrapped"
    "steam-jupiter-unwrapped"
    "steam-original"
    "steam-run"
    "steamdeck-hw-theme"
    "jovian-jupiter-hw-support"
  ];

  environment.systemPackages = with pkgs; [
  ];
}
