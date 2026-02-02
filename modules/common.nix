{ pkgs, ... }: {

  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Required for many games/Steam
  };

  networking.networkmanager.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  system.stateVersion = "24.11";
}