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
      inherit (config.mine.base) user;

      waybar-weather = pkgs.writeShellApplication {
        name = "waybar-weather";
        runtimeInputs = with pkgs; [
          curl
          cacert
          jq
          libnotify
          coreutils
          gawk
        ];
        text = builtins.readFile ./scripts/weather.sh;
      };

      # 0.15.0 sends legacy dispatch strings that hyprland's lua config rejects,
      # breaking workspace clicks; fixed upstream after the release
      waybar =
        if pkgs.waybar.version == "0.15.0" then
          pkgs.waybar.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [
              (pkgs.fetchpatch {
                name = "waybar-hyprland-lua-dispatch.patch";
                url = "https://github.com/Alexays/Waybar/commit/e17c0d9f0a73acc370df60ec8c532b1ed2385c73.patch";
                # scroll-to-switch in workspaces.cpp landed after 0.15.0, nothing to patch there
                excludes = [ "src/modules/hyprland/workspaces.cpp" ];
                hash = "sha256-QsPcxs6B8YPIPE3IzBuxER+12Ur+3JoshouDm/3T3xE=";
              })
            ];
          })
        else
          pkgs.waybar;
    in
    {
      options.mine.desktop.waybar = {
        enable = lib.mkEnableOption "Enable waybar";
        theme = lib.mkOption {
          description = "Lazy attribute set of Waybar themes.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, ... }:
              {
                options = {
                  enable = lib.mkEnableOption "this waybar theme";
                };
              }
            )
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
            ExecStart = "${waybar}/bin/waybar -c /etc/waybar/config -s /etc/waybar/style.css";
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
          waybar-weather
        ];

        sops = {
          secrets."hass/WAYBAR_TOKEN" = { };
          secrets."hass/LONGITUDE" = { };
          secrets."hass/LATITUDE" = { };
          templates."waybar-hass.token" = {
            owner = "${user.name}";
            content = ''
              ${config.sops.placeholder."hass/WAYBAR_TOKEN"}
            '';
          };
          templates."waybar-geo.env" = {
            owner = "${user.name}";
            content = ''
              LON=${config.sops.placeholder."hass/LONGITUDE"}
              LAT=${config.sops.placeholder."hass/LATITUDE"}
            '';
          };
        };
      };
    };
}
