_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.syncthing;
      inherit (config.mine.base) user;

      allDevices = {
        "wormhole" = {
          id = "25VZXUA-7CDBEMH-K6VHAB2-J6HRAP4-REKJSX6-IMHP2PP-GW4AX2P-CGZAGQ5";
        };
        "mbp" = {
          id = "GYCZLRD-BUOC3RH-4YKOVAT-Y23ZR7I-MXU6IMS-2NQXQBG-MDPXZYL-W2EGNAM";
        };
        "pixel7-pro" = {
          id = "ZAUOHVT-PXVJHPM-UH7SJCB-2SVM6V4-LKAZM4J-UMOMWZ5-4HMOMXI-FECL3QH";
        };
        "borrowbox" = {
          id = "QETZY3N-4PBJCU3-TKSWFRM-27YHJFD-CE6T3XB-ASP4SUB-EN2SMH5-GZ67GA7";
        };
        "c137" = {
          id = "WHNBVSV-DCPA2ZK-KMFSON2-X5D6D2C-47TAGSP-6OIPQ4R-Z3JDFHQ-Q662OQ4";
        };
      };

      resolvedDevices =
        if builtins.isList cfg.devices then
          lib.genAttrs cfg.devices (name: allDevices.${name} or { })
        else
          cfg.devices;

      folderDeviceNames = lib.unique (
        lib.concatLists (lib.mapAttrsToList (_: folder: folder.devices or [ ]) cfg.folders)
      );

      folderDevicesAttrs = lib.genAttrs folderDeviceNames (name: allDevices.${name} or { });

      finalDevices = lib.filterAttrs (_: value: value ? id) (
        lib.recursiveUpdate folderDevicesAttrs resolvedDevices
      );
    in
    {
      options.mine.services.syncthing = {
        enable = lib.mkEnableOption "Enable syncthing service";

        devices = lib.mkOption {
          type =
            with lib.types;
            oneOf [
              (listOf str)
              (attrsOf anything)
            ];
          default = [ ];
          description = "Declarative Syncthing devices configuration";
        };

        folders = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Declarative Syncthing folders configuration";
        };
      };

      config = lib.mkIf cfg.enable {
        services.syncthing = {
          enable = true;
          openDefaultPorts = true;
          user = user.name;
          dataDir = user.homeDir; # Default location to place the folders if absolute path is not given
          configDir = "${user.homeDir}/.config/syncthing";
          guiAddress = "0.0.0.0:8384";

          settings = {
            devices = finalDevices;
            folders = cfg.folders;
            gui = {
              theme = "dark";
              insecureSkipHostcheck = true;
              insecureAdminAccess = true;
            };
          };
        };

        mine.homelab.${config.networking.hostName} = {
          apps.syncthing = {
            traefik.static = {
              syncthing = {
                subDomain = "syncthing-${config.networking.hostName}";
                port = 8384;
              };
            };
          };
        };

        networking.firewall.allowedTCPPorts = [
          8384
          22000
        ];
        networking.firewall.allowedUDPPorts = [
          22000
          21027
        ];
      };
    };
}
