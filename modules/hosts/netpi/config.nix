_: {
  configurations.nixos.netpi.module =
    {
      config,
      lib,
      hostName,
      hostIp,
      ...
    }:
    let
      inherit (lib.thurs) enabled;
    in
    {

      mine = {
        base = {
          networking = {
            inherit hostName;
            meta = {
              inherit hostIp;
            };
          };
        };

        services = {
          traefik = enabled;
          tailscale = {
            useRoutingFeatures = "server";
            extraUpFlags = [ "--advertise-routes=192.168.10.0/24" ];
          };
        };
      };
    };
}
