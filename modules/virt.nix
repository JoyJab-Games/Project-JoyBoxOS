{ config, pkgs, ... }:

{
  imports = [ <nixpkgs/nixos/modules/virtualisation/qemu-vm.nix> ];

  # Optimization for VM Graphics
  # virtualisation.qemu.options = [ "-vga virtio" "-display gtk,gl=off" ];
  # virtualisation.qemu.options = [ "-device virtio-vga-gl -display gtk,gl=on" ];
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 2;
    qemu.options = [
      "-device virtio-gpu-gl-pci,vulkan=on,blob=true"
      "-display gtk,gl=on"
    ];
  };

  # Optional: Ensure the guest agent is running for better host-guest integration
  services.qemuGuest.enable = true;
}