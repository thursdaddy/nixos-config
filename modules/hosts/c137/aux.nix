_: {
  configurations.nixos.c137.module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      nixpkgs.config.allowUnfree = true;

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
        logitech.wireless = {
          enable = true;
          enableGraphical = true;
        };
      };

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

      services.ollama = {
        environmentVariables = {
          HSA_OVERRIDE_GFX_VERSION = "10.3.0";
        };
      };

      systemd.services.beszel-agent = {
        path = lib.mkIf config.mine.desktop.amd.enable [ pkgs.rocmPackages.rocm-smi ];
      };
    };
}
