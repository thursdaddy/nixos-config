{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.services.input-remapper;

in
{
  options.mine.services.input-remapper = {
    enable = mkEnableOption "Enable input-remapper";
  };

  config = mkIf cfg.enable {
    # re-map kensington trackball buttons
    services.input-remapper = {
      enable = true;
      serviceWantedBy = [ "multi-user.target" ];
    };

    systemd.user.services.input-remapper-autoload = {
      description = "Run input-remapper-control autoload command";
      documentation = [ "https://github.com/sezanzeb/input-remapper" ];
      enable = true;
      partOf = [ "desktop.service" ];
      after = [ "input-remapper.service" ];
      wantedBy = [ "desktop.service" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
        ExecStart = "${pkgs.input-remapper}/bin/input-remapper-control --command autoload";
      };
    };
  };
}
