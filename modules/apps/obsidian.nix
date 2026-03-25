_: {
  flake.modules.nixos.apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.config = {
        permittedInsecurePackages = [
          "electron-25.9.0"
        ];
      };

      systemd.user.services.obsidian = {
        description = "Obsidian Desktop Autostart";
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        path = [ config.system.path ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.obsidian}";
          Restart = "on-failure";
          RestartSec = "5s";
          KillMode = "mixed";
          Slice = "app.slice";
        };
      };

      environment.systemPackages = with pkgs; [
        obsidian
      ];
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "obsidian" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Obsidian.app" ];
  };
}
