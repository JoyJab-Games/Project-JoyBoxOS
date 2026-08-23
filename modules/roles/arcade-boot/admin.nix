{ config, lib, ... }: {

  users.users.admin = {
    isNormalUser = true;
    description = "Admin Mode";
    extraGroups = [ "wheel" "networkmanager" "video" "render" "input" ];
    initialPassword = "admin";
    openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPeW2xuCUp/YHSlMLXqKTEfij+yX9c351z7ocr511/JM jesco.vogt@joyjab.games"
      ];
  };

  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;

  services.tailscale.enable = true;
}