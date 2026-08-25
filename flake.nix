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
    # git+ssh, not github: - arcade-launcher-corpo is a private repo, and
    # the github: shorthand needs a GitHub API token (nix.conf
    # access-tokens) for private repos, which building this flake
    # shouldn't have to depend on for every dev. SSH key access is
    # already the expected baseline for anyone working on this anyway.
    #
    # ?ref=hardware-gamescope-test: TEMPORARY, for real-hardware testing
    # of arcade-launcher-corpo's still-unmerged in-game overview/overlay
    # work (evdev overview input, gamescope embedded-mode dev-testing
    # docs) before it lands on that repo's main. Point this back at plain
    # `main` (drop the `?ref=...`) once that branch is merged there.
    arcade-launcher.url = "git+ssh://git@github.com/JoyJab-Games/arcade-launcher-corpo.git?ref=hardware-gamescope-test";
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
