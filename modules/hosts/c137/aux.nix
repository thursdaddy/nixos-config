_: {
  configurations.nixos.c137.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        flycast
        freecad
        gimp
        gthumb
        inkscape
        unstable.keymapp
      ];

      hardware = {
        xone.enable = true; # game controller
        keyboard.zsa.enable = true;
      };

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "xow_dongle-firmware"
        ];

      # disable devices that trigger wake
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

      # re-map kensington trackball buttons
      services.input-remapper = {
        enable = true;
        serviceWantedBy = [ "multi-user.target" ];
      };

      systemd.user.services.input-remapper-autoload = {
        description = "Run input-remapper-control autoload command";
        documentation = [ "https://github.com/sezanzeb/input-remapper" ];
        enable = true;
        after = [ "input-remapper.service" ];
        partOf = [ "desktop.service" ];
        wantedBy = [ "desktop.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
          ExecStart = "${pkgs.input-remapper}/bin/input-remapper-control --command autoload";
        };
      };

      services.ollama = {
        environmentVariables = {
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        };
      };

      systemd.services.beszel-agent = lib.mkIf config.mine.services.beszel-agent.enable {
        path = lib.mkIf config.mine.desktop.amd.enable [ pkgs.rocmPackages.rocm-smi ];
      };
    };
}
