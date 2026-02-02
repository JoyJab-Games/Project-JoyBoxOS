{ config, lib, ... }: {
  options.profiles.adminDesktop.enable = lib.mkEnableOption "KDE Plasma Admin Environment";

  config = lib.mkIf config.profiles.adminDesktop.enable {

    users.users.admin = {
      isNormalUser = true;
      description = "Admin Mode";
      extraGroups = [ "wheel" "networkmanager" ];
      initialPassword = "admin";
      openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3Nza... your-public-key"
        ];
    };

    services.desktopManager.plasma6.enable = true;
    services.xserver.enable = lib.mkDefault true; # Required for Plasma

    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
    services.openssh.settings.KbdInteractiveAuthentication = false;
  };
}