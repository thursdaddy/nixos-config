{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkIf;
  inherit (config.mine) user;
  cfg = config.mine.desktop.hyprlock;

in
{
  config = mkIf cfg.enable {
    systemd.services.lock-on-suspend = {
      description = "Lock on suspend";
      wantedBy = [
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      before = [
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      environment = {
        DISPLAY = ":0";
        WAYLAND_DISPLAY = "wayland-1";
        XDG_RUNTIME_DIR = "/run/user/1000";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.hyprlock}";
        User = user.name;
      };
    };

    # hyprlock needs a secong to complete before suspending
    systemd.services.sleep-before-suspend = {
      description = "Sleep before suspend";
      wantedBy = [
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      before = [
        "sleep.target"
        "suspend.target"
        "hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 1";
        ExecStart = "${lib.getExe' pkgs.coreutils "true"}";
      };
    };
  };
}
