_: {
  flake.modules.nixos.apps =
    {
      lib,
      pkgs,
      ...
    }:
    let
      unwrapped = pkgs.unstable.discord;
      discordBypass = pkgs.writeShellScript "discord-vpn-bypass" ''
        if [ "$(${pkgs.coreutils}/bin/id -gn)" != "vpn-bypass" ]; then
          exec /run/wrappers/bin/sg vpn-bypass -c "exec ${lib.getExe unwrapped} ''${*@Q}"
        fi
        exec ${lib.getExe unwrapped} "$@"
      '';
      package = pkgs.symlinkJoin {
        name = "discord-vpn-bypass-${unwrapped.version}";
        paths = [ unwrapped ];
        postBuild = ''
          rm -f $out/bin/Discord $out/bin/discord
          ln -s ${discordBypass} $out/bin/Discord
          ln -s $out/bin/Discord $out/bin/discord
        '';
      };
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
        partOf = [ "graphical-session.target" ];
        path = [
          "/run/wrappers"
          "/run/current-system/sw"
        ];
        restartIfChanged = false;
        serviceConfig = {
          ExecStart = "${package}/bin/Discord";
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
