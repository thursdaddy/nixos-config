_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.sleep-on-lan;
    in
    {
      options.mine.services.sleep-on-lan = {
        enable = lib.mkEnableOption "Enable sleep-on-lan";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.sleep-on-lan
        ];

        networking.firewall.allowedUDPPorts = [ 9 ];
        networking.firewall.allowedTCPPorts = [
          9
          8009
        ];

        systemd.services.sleep-on-lan = {
          enable = true;
          description = "Enable sleep-on-lan daemon";
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.sleep-on-lan}/bin/sleep-on-lan";
            ExecStop = "${pkgs.coreutils}/bin/kill -SIGTERM $MAINPID";
            Restart = "always";
          };
        };
      };
    };
}
