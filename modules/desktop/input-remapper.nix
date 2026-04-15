_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      # re-map kensington trackball buttons
      services.input-remapper = {
        enable = true;
        serviceWantedBy = [ "multi-user.target" ];
      };

      systemd.user.services.input-remapper-autoload = {
        description = "Run input-remapper-control autoload command";
        documentation = [ "https://github.com/sezanzeb/input-remapper" ];
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.input-remapper}/bin/input-remapper-control --command autoload";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
        };
      };
    };
}
