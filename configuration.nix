{ config, pkgs, ... }:

{
  imports = [
    ./modules/common.nix
    ./modules/arcade-mashine.nix
    ./modules/admin-desktop.nix
    ./modules/virt.nix
    ./modules/plymouth-joyjab-arcade
  ];

  # Enable our custom modules
  profiles.arcadeMode.enable = true;
  profiles.adminDesktop.enable = true;

  # Plymouth setup
  boot.plymouth.enable = true;
}
