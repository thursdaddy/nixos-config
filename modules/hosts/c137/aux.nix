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

      # Disable USB wakeup for all USB devices except Kensington SlimBlade Pro Trackball (047d:80d6)
      services.udev.extraRules = ''
        ACTION=="add|change", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{idVendor}!="047d", ATTR{power/wakeup}="disabled"
        ACTION=="add|change", SUBSYSTEM=="usb", DRIVER=="usb", ATTR{idVendor}=="047d", ATTR{idProduct}=="80d6", ATTR{power/wakeup}="enabled"
        ACTION=="add|bind", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTRS{idVendor}!="047d", ATTR{../power/wakeup}="disabled"
        ACTION=="add|bind", SUBSYSTEM=="usb", DRIVER=="usbhid", ATTRS{idVendor}=="047d", ATTRS{idProduct}=="80d6", ATTR{../power/wakeup}="enabled"
      '';

      # disable devices that trigger wake (keep GP13/XHC0 enabled for trackball)
      systemd.services.udev-suspend-fix = {
        description = "disable ACPI wakeup devices to fix systemctl suspend";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
        };
        script = ''
          for device in GP12 BXBR SWUS SWDS GPP8 GPP0; do
            if grep -qw "^$device.*enabled" /proc/acpi/wakeup; then
              echo "$device" > /proc/acpi/wakeup
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
