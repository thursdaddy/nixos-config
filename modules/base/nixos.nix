_: {
  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      systemd.settings.Manager = {
        "DefaultTimeoutStopSec" = "15s";
        "DefaultRestartSec" = "1s";
      };
    };
}
