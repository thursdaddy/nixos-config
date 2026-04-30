_: {
  flake.modules.nixos.desktop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      myswaync = pkgs.symlinkJoin {
        name = "swaync";
        paths = [ pkgs.swaynotificationcenter ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/swaync \
            --add-flags "--config /etc/xdg/swaync/config.json" \
            --add-flags "--style /etc/xdg/swaync/style.css"
        '';
      };
    in
    {
      environment = {
        systemPackages = with pkgs; [
          libnotify
          myswaync
        ];
      };

      environment.etc = {
        "xdg/swaync/style.css".source = ./style.css;

        "xdg/swaync/config.json".text = builtins.toJSON {
          "$schema" = "${pkgs.swaynotificationcenter}/etc/xdg/swaync/config.schema.json";
          "positionX" = "center";
          "positionY" = "top";
          "layer" = "top";
          "layer-shell" = true;
          "cssPriority" = "application";
          "control-center-width" = 450;
          "control-center-height" = 500;
          "control-center-margin-top" = 15;
          "notification-window-width" = 400;
          "notification-icon-size" = 36;
          "notification-body-image-height" = 100;
          "notification-body-image-width" = 200;
          "fit-empty-params" = true;
          "hide-on-clear" = false;
          "timeout" = 10;
          "timeout-low" = 5;
          "timeout-critical" = 0;
          "widgets" = [
            "title"
            "dnd"
            "notifications"
          ];
          "widget-config" = {
            "title" = {
              "text" = "Notifications";
              "clear-all-button" = true;
              "button-text" = "Clear All";
            };
            "dnd" = {
              "text" = "Do Not Disturb";
            };
            "notifications" = {
              "max-count" = 20;
            };
          };
        };
      };
    };
}
