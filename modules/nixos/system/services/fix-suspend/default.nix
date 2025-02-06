{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.services.fix-suspend;

in
{
  options.mine.system.services.fix-suspend = {
    enable = mkEnableOption "Enable udev rule to fix systemctl suspend from immediately waking up";
  };

  config = mkIf cfg.enable {
    systemd.services.udev-suspend-fix = {
      description = "add udev rule to fix systemctl suspend";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        devices=(GP12 BXBR GP13 SWUS SWDS GPP8 GPP0)
        for device in $devices; do
          if $(grep -qw "^$device.*enabled" /proc/acpi/wakeup); then
            echo $device | tee /proc/acpi/wakeup
          fi
        done
      '';
    };
  };
}
