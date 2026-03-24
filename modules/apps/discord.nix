_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    let
      package = pkgs.unstable.discord;
    in
    {
      environment.systemPackages = [
        package
      ];

      systemd.user.services.discord = {
        description = "Discord Desktop Autostart";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe package}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "discord"
        ];
    };

  flake.modules.darwin.apps =
    { pkgs, lib, ... }:
    {
      homebrew.casks = [ "discord" ];

      system.defaults.dock.persistent-apps = [ "/Applications/Discord.app" ];
    };
}
