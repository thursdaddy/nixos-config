_: {
  configurations.nixos.tailpi.module =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        cryptsetup
      ];

      mine = {
        base.networking.hostName = "tailpi";
        services.tailscale.enable = false;
      };
    };
}
