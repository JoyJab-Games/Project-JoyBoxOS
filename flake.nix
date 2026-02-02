{
  description = "JoyJab Arcade Machine Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";

  };

  outputs = { self, nixpkgs, disko, ... }:
  let
    mkMachine = name: hardware: role: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        ./modules/common
        ./modules/hardware/${hardware}
        ./modules/roles/${role}
        { networking.hostName = name; }
      ];
    };
    versionData = builtins.fromJSON (builtins.readFile ./version.json);
    version = versionData.version;
  in {
    nixosConfigurations = {
      "geekom-a6-steam-boot" = mkMachine "geekom-a6-steam-boot" "geekom-a6" "steam-boot";
    };
  };
}
