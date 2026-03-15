_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.syncthing;
      inherit (config.mine.base) user;
    in
    {
      options.mine.services.syncthing = {
        enable = lib.mkEnableOption "Enable syncthing service";
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          openDefaultPorts = true;
          user = user.name;
          configDir = "${user.homeDir}/.config/syncthing";
        };

        systemd.user.services.syncthing-tray = {
          description = "autostart service for syncthing tray";
          documentation = [ "https://github.com/Martchus/syncthingtray" ];
          enable = true;
          partOf = [ "desktop.service" ];
          wantedBy = [ "desktop.service" ];
          serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
            ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
            ExecStop = "${pkgs.coreutils}/bin/kill -SIGUSR3 $MAINPID";
            Restart = "always";
            KillMode = "mixed";
          };
        };

        networking.firewall.allowedTCPPorts = [
          8384
          22000
        ];
        networking.firewall.allowedUDPPorts = [
          22000
          21027
        ];
      };
    };
}
