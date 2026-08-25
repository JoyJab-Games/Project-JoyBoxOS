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

  # `arcade install`/`update`/`release` run as whichever user invokes
  # them, and arcade-launcher-corpo's own launch code chmod's a game's
  # executable at every launch (steamcmd binaries don't reliably come out
  # with +x set) - chmod is an owner-only operation, so a game installed
  # by admin can never be chmod'd (and therefore never launched) by gamer,
  # who actually runs the session (see ./gamescope-session.nix). Silently
  # re-target `arcade` to run as gamer instead, so admin (the only user
  # with SSH access) can keep using it exactly as before without needing
  # to remember `sudo -u gamer` by hand each time, or files ending up
  # owned by a user that can't act on them - confirmed to actually bite on
  # real hardware 2026-08-25 (installed as admin, "Operation not
  # permitted" chmod failure when gamer's session tried to launch it).
  environment.shellAliases.arcade = "sudo -u gamer arcade";
}