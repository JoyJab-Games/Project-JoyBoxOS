{
  description = "JoyJab Arcade Machine Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    disko.url = "github:nix-community/disko";
    # arcade-launcher-corpo: the actual game launcher this cabinet boots
    # into (see modules/roles/arcade-boot) - packages.default/arcade-cli.
    # No `inputs.nixpkgs.follows` here: it pins its own nixpkgs for its
    # Rust/Godot build reproducibility (see its own nixos/default.nix),
    # deliberately not required to match this flake's nixpkgs revision.
    # github: shorthand, not git+ssh - arcade-launcher-corpo is now public,
    # so no SSH key or GitHub API token is needed to fetch it. (It used to
    # be private and required git+ssh; switch back only if it goes private
    # again.)
    #
    # hardware-gamescope-test's in-game overview/overlay work (evdev
    # overview input, gamescope embedded-mode dev-testing docs) plus the
    # steamcmd Windows-platform-detection fix (2026-08-27) are now
    # confirmed working on real hardware and merged to main (fast-forward,
    # 90c9f08..2316629) - back to tracking plain `main`, no `?ref=...`.
    arcade-launcher.url = "github:JoyJab-Games/arcade-launcher-corpo";
  };

  outputs = { self, nixpkgs, disko, arcade-launcher, ... }:
  let
    mkMachine = name: hardware: role: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit arcade-launcher; };
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
      "geekom-a6-arcade-boot" = mkMachine "geekom-a6-arcade-boot" "geekom-a6" "arcade-boot";
    };
  };
}
