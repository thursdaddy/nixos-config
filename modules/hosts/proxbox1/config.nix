_: {
  configurations.nixos.proxbox1.module =
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
            hostName = "proxbox1";
            ipv4Forwarding = enabled;
            meta = {
              hostIp = "192.168.10.120";
            };
          };
          utils.sysadmin = enabled;
        };
      };
    };
}
