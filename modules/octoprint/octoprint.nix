_: {
  flake.modules.nixos.octoprint =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      name = "octoprint";
      cfg = config.mine.services.${name};
      port = "5000";

      octoStream = "octostream";
      octoStreamCfg = config.mine.services.${octoStream};
      cabinetStream = "cabinetstream";
      cabinetStreamCfg = config.mine.services.${cabinetStream};
    in
    {
      options.mine.services = {
        ${name} = {
          enable = lib.mkOption {
            description = "Enable ${name}";
            type = lib.types.bool;
            default = true;
          };
          subdomain = lib.mkOption {
            description = "Container url, used by blocky to create DNS entry";
            type = lib.types.str;
            default = name;
          };
          port = lib.mkOption {
            description = "Port";
            type = lib.types.str;
            default = port;
          };
        };
        ${octoStream} = {
          enable = lib.mkOption {
            description = "Enable ${octoStream}";
            type = lib.types.bool;
            default = true;
          };
          subdomain = lib.mkOption {
            description = "Stream url, used by blocky to create DNS entry";
            type = lib.types.str;
            default = octoStream;
          };
          port = lib.mkOption {
            description = "Port";
            type = lib.types.str;
            default = "8080";
          };
        };
        ${cabinetStream} = {
          enable = lib.mkOption {
            description = "Enable ${cabinetStream}";
            type = lib.types.bool;
            default = true;
          };
          subdomain = lib.mkOption {
            description = "Stream url, used by blocky to create DNS entry";
            type = lib.types.str;
            default = cabinetStream;
          };
          port = lib.mkOption {
            description = "Port";
            type = lib.types.str;
            default = "9090";
          };
        };
      };

      config = lib.mkIf cfg.enable {
        services.octoprint = {
          enable = true;
          # some octoprint plugins are not backwards compatible with python 3.13 as the "future" module is not supported in python 3.13
          package = pkgs.octoprint.override {
            python3 = pkgs.python312;
          };
          openFirewall = true;
          extraConfig = {
            plugins = {
              _disabled = [
                "softwareupdate"
                "firmware_check"
              ];
            };
            folder = {
              timelapse = "/opt/configs/octoprint/timelapse/";
              uploads = "/opt/configs/octoprint/uploads/";
            };
            server = {
              commands = {
                serverRestartCommand = "/run/wrappers/bin/sudo /run/current-system/sw/bin/systemctl restart octoprint";
                systemRestartCommand = "/run/wrappers/bin/sudo reboot -h now";
              };
            };
            printerProfiles = {
              default = "_default";
              defaultProfile = {
                axes = {
                  e = {
                    inverted = false;
                    speed = 300;
                  };
                  x = {
                    inverted = false;
                    speed = 6000;
                  };
                  y = {
                    inverted = false;
                    speed = 6000;
                  };
                  z = {
                    inverted = false;
                    speed = 200;
                  };
                  color = "default";
                  extruder = {
                    count = 1;
                    defaultExtrusionLength = 5;
                    nozzleDiameter = 0.4;
                    sharedNozzle = false;
                  };
                };
                heatedBed = true;
                heatedChamber = false;
                id = "_default";
                model = "Prusa MK3S";
                name = "Prusa MK3S";
                volume = {
                  custom_box = {
                    x_max = 250.0;
                    x_min = 0.0;
                    y_max = 210.0;
                    y_min = -4.0;
                    z_max = 200.0;
                    z_min = 0.0;
                  };
                  depth = 210.0;
                  formFactor = "rectangular";
                  height = 200.0;
                  origin = "lowerleft";
                  width = 250.0;
                };
              };
            };
            plugins = {
              PrintJobHistory = {
                capturePrintJobHistoryMode = "always";
                currencySymbol = "$";
                lastPluginDependencyCheck = "1.17.2";
                selectedFilamentTrackerPlugin = "SpoolManager Plugin";
              };
              tplinksmartplug = {
                abortTimeout = "300";
                cost_rate = ".10";
                event_on_shutdown_monitoring = true;
                event_on_startup_monitoring = true;
                event_on_upload_monitoring = true;
                event_on_upload_monitoring_always = false;
                idleTimeout = "20";
                idleTimeoutWaitTemp = "35";
                pollingEnabled = true;
                pollingInterval = "1";
                powerOffWhenIdle = true;
                thermal_runaway_max_bed = "180";
                thermal_runaway_max_extruder = "320";
                thermal_runaway_monitoring = true;
                # this part breaks the plugin :(
                # arrSmartplugs = [{
                #   autoConnect = true;
                #   autoConnectDelay = 10;
                #   autoDisconnect = true;
                #   autoDisconnectDelay = 0;
                #   automaticShutdownEnabled = true;
                #   btnColor = "#808080";
                #   countdownOffDelay = 1;
                #   emeter = { get_realtime = { }; };
                #   countdownOnDelay = 1;
                #   displayWarning = true;
                #   event_on_disconnect = false;
                #   event_on_error = false;
                #   event_on_shutdown = false;
                #   event_on_startup = false;
                #   event_on_upload = true;
                #   gcodeCmdOff = false;
                #   gcodeCmdOn = false;
                #   gcodeEnabled = false;
                #   gcodeOffDelay = 0;
                #   gcodeOnDelay = 0;
                #   icon = "icon-bolt";
                #   ip = "192.168.20.65/2";
                #   label = "strip";
                #   sysCmdOff = false;
                #   sysCmdOffDelay = 0;
                #   sysCmdOn = false;
                #   sysCmdOnDelay = 0;
                #   thermal_runaway = true;
                #   useCountdownRules = true;
                #   warnPrinting = true;
                # }];
              };
            };
          };
          plugins =
            plugins: with plugins; [
              camerasettings
              displaylayerprogress
              mqtt
              octoprint-cancelobject
              octoprint-costestimation
              octoprint-dashboard
              octoprint-excluderegion
              octoprint-filemanager
              octoprint-homeassistant
              # octoprint-multicam
              octoprint-octolight-home-assistant
              octoprint-powerfailure
              octoprint-preheat
              octoprint-prettygcode
              octoprint-printjobhistory
              octoprint-printtimegenius
              octoprint-prusaslicerthumbnails
              octoprint-slicerestimator
              octoprint-spoolmanager
              octoprint-tplinksmartplug
              octoprint-uicustomizer
              timelapse
            ];
        };

        mine.base.nfs-mounts = {
          enable = true;
          mounts = {
            "/opt/configs" = {
              device = "192.168.10.12:/fast/configs/printpi";
              options = [
                "auto"
                "rw"
                "defaults"
                "_netdev"
                "x-systemd.automount"
              ];
            };
          };
        };

        systemd.services = {
          octoprint = {
            after = lib.mkForce [ "mount-configs.service" ];
            path = with pkgs; [
              python3Packages.pip
              v4l-utils
            ];
            serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          };

          ${octoStream} = {
            serviceConfig = {
              ExecStart = "${pkgs.unstable.ustreamer}/bin/ustreamer --device=/dev/video0 --resolution=1920x1080 --desired-fps=60 --format=MJPEG --host=127.0.0.1 --port=${octoStreamCfg.port} --encoder=hw --workers=3 --persistent";
            };
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
          };

          ${cabinetStream} = {
            serviceConfig = {
              ExecStart = "${pkgs.unstable.ustreamer}/bin/ustreamer --device=/dev/video2 --resolution=1920x1080 --desired-fps=15 --format=MJPEG --host=127.0.0.1 --port=${cabinetStreamCfg.port} --encoder=hw --workers=3 --persistent";
            };
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
          };

          mount-configs = {
            description = "mount nfs containing model files, timelapse and plugin files";
            wantedBy = [ "multi-user.target" ];
            after = [ "network-online.target" ];
            requires = [ "network-online.target" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
            };
            script = ''
              # mount /opt/configs
              ${pkgs.sudo}/bin/sudo /run/wrappers/bin/mount /opt/configs

              # symlink plugin data from /opt/configs
              source_path='
              SpoolManager
              PrintJobHistory
              prusaslicerthumbnails
              '

              for path in $source_path; do
                ${pkgs.coreutils}/bin/rm -rfv /var/lib/octoprint/data/$path
                ${pkgs.coreutils}/bin/ln -s /opt/configs/octoprint/plugins/$path /var/lib/octoprint/data/
                ${pkgs.coreutils}/bin/chown -Rv octoprint:octoprint /var/lib/octoprint/data/$path
              done
            '';
          };
        };

        security.sudo.extraRules = [
          {
            users = [ "octoprint" ];
            commands = [
              {
                command = "ALL";
                options = [ "NOPASSWD" ];
              }
            ];
          }
        ];

        users.users.octoprint.extraGroups = [
          "video"
        ];

        environment.systemPackages = with pkgs; [
          ffmpeg
          v4l-utils # camera control
        ];

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
            traefikOctoPrint = lib.thurs.mkTraefikFile {
              inherit config;
              name = cfg.subdomain;
              inherit port;
            };
            traefikOctoStream = lib.thurs.mkTraefikFile {
              inherit config;
              name = octoStreamCfg.subdomain;
              port = octoStreamCfg.port;
            };
            traefikCabinetStream = lib.thurs.mkTraefikFile {
              inherit config;
              name = cabinetStreamCfg.subdomain;
              port = cabinetStreamCfg.port;
            };
          in
          builtins.listToAttrs [
            alloyJournal
            traefikOctoPrint
            traefikOctoStream
            traefikCabinetStream
          ];
      };
    };
}
