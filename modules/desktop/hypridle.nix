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

      hypridle-ctl = pkgs.writeShellApplication {
        name = "hypridle-ctl";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.procps
          pkgs.systemd
          pkgs.libnotify
        ];
        text = ''
          RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
          STATE_FILE="''${RUNTIME_DIR}/hypridle-no-sleep"

          signal_waybar() {
            if pgrep -x waybar >/dev/null; then
              pkill -RTMIN+8 waybar
            fi
          }

          notify_user() {
            local title="$1"
            local body="$2"
            if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -S "''${RUNTIME_DIR}/bus" ]; then
              notify-send -u low -t 2500 -a "Hypridle" "$title" "$body"
            fi
          }

          case "''${1:-status}" in
            status)
              if ! systemctl --user is-active --quiet hypridle.service; then
                printf '%s\n' '{"text":"󰒳 ","alt":"stopped","class":"stopped","tooltip":"Hypridle: Stopped (auto-lock, screen off, and suspend disabled)"}'
              elif [ -e "$STATE_FILE" ]; then
                printf '%s\n' '{"text":"󰒳 ","alt":"inhibited","class":"inhibited","tooltip":"Stay-Awake: Sleep disabled (5m lock & 10m screen off active)"}'
              else
                printf '%s\n' '{"text":"󰒲 ","alt":"active","class":"active","tooltip":"Hypridle: Active (5m lock, 10m screen off, 15m suspend)"}'
              fi
              ;;
            toggle)
              if ! systemctl --user is-active --quiet hypridle.service; then
                systemctl --user start hypridle.service
              fi
              if [ -e "$STATE_FILE" ]; then
                rm -f "$STATE_FILE"
                signal_waybar
                notify_user "Sleep Enabled" "15m auto-suspend restored (5m lock, 10m screen off)"
              else
                touch "$STATE_FILE"
                signal_waybar
                notify_user "Stay-Awake Enabled" "Auto-suspend disabled (5m lock & 10m screen off active)"
              fi
              ;;
            toggle-service)
              if systemctl --user is-active --quiet hypridle.service; then
                systemctl --user stop hypridle.service
                signal_waybar
                notify_user "Hypridle Stopped" "Auto-lock, screen off, and suspend disabled"
              else
                systemctl --user start hypridle.service
                signal_waybar
                notify_user "Hypridle Started" "Idle timers restored"
              fi
              ;;
            suspend-if-allowed)
              if [ ! -e "$STATE_FILE" ]; then
                systemctl suspend
              fi
              ;;
            *)
              printf 'Usage: %s {status|toggle|toggle-service|suspend-if-allowed}\n' "$0" >&2
              exit 1
              ;;
          esac
        '';
      };

      # hyprctl dispatch takes a lua dispatcher expression when hyprland runs a lua config
      dpms =
        action:
        "${lib.getExe' config.programs.hyprland.package "hyprctl"} dispatch 'hl.dsp.dpms({ action = \"${action}\" })'";

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
            on-timeout = dpms "off";
            on-resume = dpms "on";
          }
          {
            timeout = 900;
            on-timeout = "${lib.getExe cfg.package} suspend-if-allowed";
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
        package = lib.mkOption {
          type = lib.types.package;
          default = hypridle-ctl;
          description = "Hypridle control utility package.";
        };
      };

      config = lib.mkIf cfg.enable {
        systemd.user.services.hypridle = {
          description = "Hypridle";
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];
          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
          };
          serviceConfig = {
            ExecStart = "${lib.getExe pkgs.unstable.hypridle}";
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
            pkgs.unstable.hypridle
            cfg.package
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
