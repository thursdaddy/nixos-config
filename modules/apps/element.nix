_: {
  flake.modules.nixos.apps =
    { pkgs, ... }:
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
          Type = "oneshot";
          ExecStart = "${pkgs.input-remapper}/bin/input-remapper-control --command autoload";
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
