{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.systemd;

in
{
  options.mine.desktop.systemd = {
    enable = mkEnableOption "Enable systemd service to restart desktop services";
  };

  config = mkIf cfg.enable {
    home-manager.users.${user.name} = {
      home.packages = with pkgs; [
        (writeShellScriptBin "restart.desktop" ''
          ${config.systemd.package}/bin/systemctl --user restart desktop.service
        '')
      ];

      # Link other services to this unit:
      # PartOf = ["desktop.service" ];
      systemd.user.services.desktop = {
        Unit = {
          Description = "Systemd dummy oneshot to link desktop related services";
          After = [ "hyprland-session.target" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/sleep 1";
        };
        Install = {
          WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
