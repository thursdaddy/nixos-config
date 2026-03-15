_: {
  flake.modules.generic.apps =
    { lib, ... }:
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
        ];
    };

  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      systemd.user.services.discord = {
        description = "Discord Desktop Autostart";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.discord}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };
    };

  flake.modules.homeManager.apps =
    { pkgs, lib, ... }:
    {
      home.packages = [ pkgs.unstable.discord ];
    };
}
