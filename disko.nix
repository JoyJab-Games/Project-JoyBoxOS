{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme0n1";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # 1. Boot Partition (EFI)
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # 2. Swap Partition (8GB is plenty for your RAM)
            swap = {
              size = "8G";
              content = {
                type = "swap";
                discardPolicy = "both"; # Good for SSD health
                resumeDevice = true;    # Allows for hibernation
              };
            };
            # 3. The rest of the 1TB for NixOS
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}