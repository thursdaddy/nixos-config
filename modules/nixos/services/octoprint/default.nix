{ lib, config, pkgs, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.octoprint;
in
{
  imports = [
    ./plugins.nix
  ];

  options.mine.services.octoprint = {
    enable = mkEnableOption "Enable Octoprint";
  };

  config = mkIf cfg.enable {
    environment.etc = mkIf config.mine.container.traefik.enable {
      "traefik/octoprint.yml" = {
        text = (builtins.readFile
          (pkgs.substituteAll {
            name = "octoprint";
            src = ./traefik.yml;
            fqdn = config.mine.container.traefik.domainName;
            ip = "192.168.10.185";
          })
        );
      };
    };

    environment.systemPackages = with pkgs; [
      ffmpeg
      v4l-utils # camera control
    ];

    systemd.services = {
      octostream = {
        serviceConfig = {
          ExecStart = "${pkgs.mjpg-streamer}/bin/mjpg_streamer -i \"input_uvc.so -r 1280x720 -d /dev/video0 -f 60 -n\" -o \"output_http.so -p 8080 -w /usr/local/share/mjpg-streamer/www\"";
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        requires = [ "network-online.target" ];
      };

      octoprint = {
        after = [ "mount-configs.service" ];
        requires = [ "mount-configs.service" ];
        path = [ pkgs.python3Packages.pip pkgs.v4l-utils ];
        serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
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
          timelapse
          '

          for path in $source_path; do
            ${pkgs.coreutils}/bin/rm -rfv /var/lib/octoprint/data/$path
            ${pkgs.coreutils}/bin/ln -s /opt/configs/octoprint/plugins/$path /var/lib/octoprint/data/
            ${pkgs.coreutils}/bin/chown -Rv octoprint:octoprint /var/lib/octoprint/data/$path
          done
        '';
      };
    };

    networking.firewall.allowedTCPPorts = [ 8080 ];

    security.sudo.extraRules = [{
      users = [ "octoprint" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];

    users.users.octoprint.extraGroups = [
      "video"
    ];

    services.octoprint = {
      enable = true;
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
      plugins = plugins: with plugins; [
        camerasettings
        timelapse
        octoprint-cancelobject
        octoprint-costestimation
        octoprint-dashboard
        octoprint-displaylayerprogress
        octoprint-excluderegion
        octoprint-filemanager
        octoprint-powerfailure
        octoprint-prettygcode
        octoprint-preheat
        octoprint-printtimegenius
        octoprint-prusaslicerthumbnails
        octoprint-printjobhistory
        octoprint-slicerestimator
        octoprint-spoolmanager
        octoprint-tplinksmartplug
        octoprint-uicustomizer
      ];
    };
  };
}
