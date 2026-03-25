_: {
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.waybar;
    in
    {
      options.mine.desktop.waybar = {
        enable = lib.mkEnableOption "Enable waybar";
        theme = lib.mkOption {
          description = "Lazy attribute set of Waybar themes.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule ({
              options = {
                enable = lib.mkEnableOption "this waybar theme";
              };
            })
          );
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.waybar = {
          description = "Highly customizable Wayland bar for Sway and Wlroots based compositors.";
          documentation = [ "https://github.com/Alexays/Waybar/wiki" ];
          after = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.waybar}/bin/waybar -c /etc/waybar/config -s /etc/waybar/style.css";
            ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
            Restart = "on-failure";
            RestartSec = "2s";
            KillMode = "mixed";
            X-Restart-Triggers = [
              config.environment.etc."waybar/config".source
              config.environment.etc."waybar/style.css".source
            ];
          };
        };

        environment.systemPackages = [
          pkgs.adwaita-icon-theme
        ];
      };
    };
}
