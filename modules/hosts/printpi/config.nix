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

        containers = {
          gatus = {
            enable = true;
            endpointsFile = config.nixos-thurs.gatus.publicEndpoints;
            gotifyUrl = "https://gotify.${config.nixos-thurs.publicDomain}";
          };
          traefik = enabled;
        };

        services = {
          backups = enabled;
        };
      };
    };
}
