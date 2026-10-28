_: {
  configurations.nixos.proxbox1.module =
    {
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
          };
          utils.sysadmin = enabled;
        };

        homelab.proxbox1 = {
          hostIp = "192.168.10.120";
        };
      };
    };
}
