_: {
  flake.modules.nixos.desktop =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      environment = {
        systemPackages = with pkgs; [
          libnotify
          swaynotificationcenter
        ];
      };

      environment.etc."xdg/swaync/config.json".text = ''
        {
          "timeout": 10
        }
      '';
    };
}
