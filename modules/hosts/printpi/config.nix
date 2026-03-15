_: {
  configurations.nixos.printpi.module =
    {
      config,
      lib,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {
      mine = {
        base = {
          networking = {
            hostName = "printpi";
            meta = {
              hostIp = "192.168.10.185";
            };
          };
        };

        services = {
          traefik = enabled;
          qemu-guest = enabled;
        };
      };
    };
}
