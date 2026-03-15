_: {
  flake.modules.nixos.desktop =
    { pkgs, ... }:
    {
      # Link other services to this unit:
      # PartOf = ["desktop.service" ];
      systemd.services.desktop = {
        description = "Systemd dummy oneshot to link desktop related services";

        # System-level services usually wait for multi-user.target
        # instead of hyprland-session.target
        after = [ "display-manager.service" ];

        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.coreutils}/bin/sleep 1";
          # If this must run as a specific user, uncomment the next line:
          # User = "your-username";
        };

        wantedBy = [ "multi-user.target" ];
      };
    };
}
