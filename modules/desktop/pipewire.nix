_: {
  flake.modules.nixos.desktop =
    {
      pkgs,
      ...
    }:
    {
      environment.systemPackages = [
        pkgs.pavucontrol
      ];

      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        pulse.enable = true;
        jack.enable = true;
      };
    };
}
