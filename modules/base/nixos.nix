_: {
  flake.modules.nixos.base = {
    systemd.settings.Manager = {
      "DefaultTimeoutStopSec" = "15s";
      "DefaultRestartSec" = "1s";
    };

    boot.kernel.sysctl = {
      "fs.inotify.max_user_watches" = 524288;
    };
  };
}
