_: {
  flake.modules.nixos.apps =
    { lib, pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        element-desktop
      ];

      systemd.user.services.element-desktop = {
        description = "A glossy Matrix collaboration client for the web.";
        documentation = [ "https://github.com/element-hq/element-web" ];
        after = [ "graphical-session.target" ];
        bindsTo = [ "graphical-session.target" ];
        wantedBy = [ "graphical-session.target" ];
        serviceConfig = {
          ExecStart = "${lib.getExe pkgs.element-desktop}";
          Restart = "on-failure";
          RestartSec = "2s";
          KillMode = "mixed";
          Slice = "session.slice";
        };
      };
    };

  flake.modules.darwin.apps = {
    homebrew.casks = [ "element" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Element.app" ];
  };
}
