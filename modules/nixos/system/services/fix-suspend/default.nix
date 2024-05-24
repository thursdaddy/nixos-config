{ lib, config, ... }:
with lib;
let
  cfg = config.mine.system.services.fix-suspend;
in
{
  options.mine.system.services.fix-suspend = {
    enable = mkEnableOption "Enable udev rule to fix systemctl suspend from immediately waking up";
  };

  config = mkIf cfg.enable {
    # TODO: make this work instead of hacky systemd service
    # https://discourse.nixos.org/t/resumes-immediately-after-suspend-how-to-diagnose/34537/4
    # services.udev.extraRules = lib.concatStringsSep ", " [
    #   ''ACTION=="add"''
    #   ''SUBSYSTEM=="pci"''
    #   ''ATTR{vendor}=="0x1022"''
    #   ''ATTR{device}=="0x1484"''

    #   ''ATTR{power/wakeup}="disabled"''
    # ];

    systemd.services.udev-suspend-fix = {
      description = "add udev rule to fix systemctl suspend";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
      script = ''
        #!/usr/bin/env bash
        if ! udevadm info -a /sys/bus/pci/devices/0000:00:07.1 | grep "power/wakeup}==\"disabled\""; then
          echo "GP12" | tee /proc/acpi/wakeup
        fi
      '';
    };
  };
}
