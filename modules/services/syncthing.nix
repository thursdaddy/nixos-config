_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.syncthing;
      inherit (config.mine.base) user;
    in
    {
      options.mine.services.syncthing = {
        enable = lib.mkEnableOption "Enable syncthing service";
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          openDefaultPorts = true;
          user = user.name;
          configDir = "${user.homeDir}/.config/syncthing";
        };

        networking.firewall.allowedTCPPorts = [
          8384
          22000
        ];
        networking.firewall.allowedUDPPorts = [
          22000
          21027
        ];
      };
    };
}
