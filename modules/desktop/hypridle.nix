{ inputs, ... }:
{
  flake.modules.nixos.desktop =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.hypridle;

      # Having ongoing issues with hypridle crashing hyprlock and from looking at logs
      # it seems like hypridle is not behaving properly when its executing commands simliar to:
      # https://github.com/hyprwm/hypridle/issues/166

      # I don't seem to have these issues when managed via systemd-lock-handler and
      # systemd.user.service in hyprlock.nix
      hypridleSettings = {
        general = {
          before_sleep_cmd = "";
          after_sleep_cmd = "";
          lock_cmd = "";
        };

        listener = [
          {
            timeout = 300;
            on-timeout = "${lib.getExe' pkgs.systemd "loginctl"} lock-session";
          }
          {
            timeout = 600;
            on-timeout = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms off";
            on-resume = "${lib.getExe' pkgs.hyprland "hyprctl"} dispatch dpms on";
          }
          {
            timeout = 900;
            on-timeout = "${lib.getExe' pkgs.systemd "systemctl"} suspend";
          }
        ];
      };

      hypridleConf = lib.thurs.toHyprconf {
        attrs = hypridleSettings;
      };

      etcPath = "xdg/hypr/hypridle.conf";
    in
    {
      options.mine.desktop.hypridle = {
        enable = lib.mkEnableOption "Enable hypridle";
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.hypridle = {
          description = "Hyrpidle";
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.hypridle}";
            Type = "simple";
            Restart = "always";
            RestartSec = "10s";
            X-Restart-Triggers = [
              config.environment.etc.${etcPath}.source
            ];
          };
        };

        environment = {
          etc."${etcPath}".text = hypridleConf;
          systemPackages = [
            pkgs.hypridle
          ];
        };

        systemd.services.ssh-inhibit = {
          description = "Inhibit sleep while SSH sessions are active";
          after = [
            "network.target"
            "sshd.service"
          ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "simple";
            ExecStart = pkgs.writeShellScript "ssh-inhibit-loop" ''
              while true; do
                # Check if there are any active SSH sessions using 'who' or 'ss'
                if ${pkgs.procps}/bin/w -h | ${pkgs.gnugrep}/bin/grep -q 'pts/'; then
                  # If sessions exist, start an inhibitor that lasts for 70 seconds
                  # (slightly longer than the loop to ensure continuous coverage)
                  ${pkgs.systemd}/bin/systemd-inhibit \
                    --what=idle:sleep \
                    --who="SSH Monitor" \
                    --why="Active SSH session detected" \
                    --mode=block \
                    ${pkgs.coreutils}/bin/sleep 70 &
                fi
                sleep 60
              done
            '';
            Restart = "always";
            User = "root";
          };
        };
      };
    };
}
