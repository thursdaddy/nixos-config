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
          after = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
            ExecStart = "${pkgs.syncthingtray-minimal}/bin/syncthingtray --wait";
            Restart = "always";
            KillMode = "mixed";
            Slice = "session.slice";
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
