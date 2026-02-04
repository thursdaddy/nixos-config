_: {
  disko.devices = {
    disk = {
      configs = {
        device = "/dev/nvme1n1"; # Ensure this matches your target drive
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            configs = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/opt/configs";
                extraArgs = [
                  "-L"
                  "configs"
                ];
              };
            };
          };
        };
      };
    };
  };
}
