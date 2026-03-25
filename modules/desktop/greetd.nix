_: {
  flake.modules.nixos.desktop =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.mine.desktop.greetd;
    in
    {
      options.mine.desktop.greetd = {
        enable = lib.mkEnableOption "Enable Greetd";
      };

      config = lib.mkIf cfg.enable {
        services.greetd = {
          enable = true;
          settings = {
            default_session = {
              command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd 'uwsm start hyprland-uwsm.desktop'";
              user = "greeter";
            };
          };
        };
      };
    };
}
