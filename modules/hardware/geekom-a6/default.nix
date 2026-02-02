{ pkgs, ... }:
{
  imports = [
    ../../../disk-layouts/1TBSSD-32GBRam.nix
    ./hardware-configuration.nix
  ];
  _module.args.disk-target = "/dev/nvme0n1";

  # we are using efi, so nodev because internet said so yes
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.kernelPackages = pkgs.linuxPackages_latest;
}
