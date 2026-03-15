_: {
  flake.modules.nixos.base =
    { lib, config, ... }:
    {
      systemd.settings.Manager = {
        "DefaultTimeoutStopSec" = "15s";
        "DefaultRestartSec" = "1s";
      };
    };
}
