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
  #
  # Plain `sudo -u gamer` switches uid but leaves the working directory
  # untouched, i.e. still admin's SSH login cwd (/home/admin, mode 700).
  # steamcmd's bubblewrap sandbox tries to chdir into that same cwd inside
  # its mount namespace, and gamer can't enter admin's home directory, so
  # bwrap fails with "Can't chdir to /home/admin: Permission denied" before
  # steamcmd even runs. `-i` makes sudo start a real login shell for
  # gamer (cwd = /home/gamer, $HOME set accordingly), which bwrap can
  # chdir into fine - confirmed 2026-08-27.
  environment.shellAliases.arcade = "sudo -i -u gamer arcade";
}