_: {
  configurations.nixos.rpi4.module =
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
            hostName = "rpi4";
            meta = {
              hostIp = "192.168.10.103";
            };
          };
        };

        services = {
          nginx = enabled;
          traefik = enabled;
          tailscale = {
            useRoutingFeatures = "server";
            extraUpFlags = [ "--advertise-routes=192.168.10.0/24" ];
          };
        };
      };
    };
}
