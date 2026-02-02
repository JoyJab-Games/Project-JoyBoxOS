{ pkgs, config, lib, ... }:
{

  users.users.gamer = {
    isNormalUser = true;
    initialPassword = "gamer";
    extraGroups = [ "video" "render" "input" ];
    description = "Arcade Mode";
  };

  services.seatd = {
    enable = true; # used by gamescope for requesting access to the gpu without root priveleges
    user = "gamer";
    group = "users";
  };

  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
    "steam"
    "steam-unwrapped"
  ];

  programs.steam = {
    enable = true;
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  services.xserver.enable = false;
  services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.cage}/bin/cage -- steam -pipewire-dmabuf -tenfoot -gamepadui";
          user = "gamer";
        };
      };
    };

  environment = {
    systemPackages = with pkgs; [
      gamescope-wsi
      cage
    ];
  };
}
