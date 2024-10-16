{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.services.octoprint;

in
{
  options.mine.services.octoprint = {
    enable = mkEnableOption "Enable Octoprint";
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 8080 ];

    systemd.services.octostream = {
      serviceConfig = {
        ExecStart = "${pkgs.mjpg-streamer}/bin/mjpg_streamer -i \"input_uvc.so -r 1920x1080 -d /dev/video0 -f 30 -n\" -o \"output_http.so -p 8080 -w /usr/local/share/mjpg-streamer/www\"";
      };
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
    };

    # TODO: only allow certain commands
    security.sudo.extraRules = [{
      users = [ "octoprint" ];
      commands = [{
        command = "ALL";
        options = [ "NOPASSWD" ];
      }];
    }];

    systemd.services.mount-configs = {
      description = "mount nfs containing model files, timelapse and plugin files";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      };
      script = ''
        #!/usr/bin/env bash
        ${pkgs.sudo}/bin/sudo /run/wrappers/bin/mount /opt/configs
        ${pkgs.coreutils}/bin/rm -rfv /var/lib/octoprint/data/SpoolManager/spoolmanager.db /var/lib/octoprint/data/PrintJobHistory
        ${pkgs.coreutils}/bin/ln -s /opt/configs/octoprint/plugins/SpoolManager/spoolmanager.db /var/lib/octoprint/data/SpoolManager/spoolmanager.db
        ${pkgs.coreutils}/bin/ln -s /opt/configs/octoprint/plugins/PrintJobHistory /var/lib/octoprint/data/
        ${pkgs.coreutils}/bin/chown -Rv octoprint:octoprint /var/lib/octoprint/data/PrintJobHistory
      '';
    };

    systemd.services.octoprint = {
      after = [ "mount-configs.service" ];
      requires = [ "mount-configs.service" ];
      path = [ pkgs.python3Packages.pip pkgs.v4l-utils ];
      serviceConfig.AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
    };

    services.octoprint = {
      enable = true;
      openFirewall = true;
      extraConfig = {
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
            model = "Prusa MK3S+";
            name = "Prusa MK3S+";
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
            event_on_upload_monitoring_always = true;
            idleTimeout = "15";
            idleTimeoutWaitTemp = "35";
            pollingEnabled = true;
            pollingInterval = "5";
            powerOffWhenIdle = true;
            thermal_runaway_max_bed = "120";
            thermal_runaway_max_extruder = "290";
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
        octolapse
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

    nixpkgs.overlays = [
      (self: super: {
        octoprint = super.octoprint.override {
          packageOverrides = pyself: pysuper: {
            camerasettings = pyself.buildPythonPackage rec {
              pname = "OctoPrint-CameraSettings";
              version = "0.4.3";
              src = self.fetchFromGitHub {
                owner = "The-EG";
                repo = "OctoPrint-CameraSettings";
                rev = "${version}";
                sha256 = "sha256-VGSlJzWYIpqBe0xe5UG6+BIveR3nfC3F/FLnSd09fH4=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-displaylayerprogress = pyself.buildPythonPackage rec {
              pname = "OctoPrint-DisplayLayerProgress";
              version = "1.28.0";
              src = self.fetchFromGitHub {
                owner = "OllisGit";
                repo = "OctoPrint-DisplayLayerProgress";
                rev = "${version}";
                sha256 = "sha256-FoQGv7a3ktodyQKOwR69/9Up+wPoW5NDq+k5LfP9WYs=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-prettygcode = pyself.buildPythonPackage rec {
              pname = "PrettyGCode";
              version = "1.2.4";
              src = self.fetchFromGitHub {
                owner = "Kragrathea";
                repo = "OctoPrint-PrettyGCode";
                rev = "v${version}";
                sha256 = "sha256-q/B2oEy+D6L66HqmMkvKfboN+z3jhTQZqt86WVhC2vQ=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-cancelobject = pyself.buildPythonPackage rec {
              pname = "OctoPrint-Cancelobject";
              version = "0.5.0";
              src = self.fetchFromGitHub {
                owner = "paukstelis";
                repo = "Octoprint-Cancelobject";
                rev = "${version}";
                sha256 = "sha256-I/uhkUO2ajgo0b9SZH6j6w1s4GoDuh1V3owPuiiFr9A=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-costestimation = pyself.buildPythonPackage rec {
              pname = "OctoPrint-CostEstimation";
              version = "3.5.0";
              src = self.fetchFromGitHub {
                owner = "OllisGit";
                repo = "Octoprint-CostEstimation";
                rev = "${version}";
                sha256 = "sha256-zlUXg+UHx3DOo8RJXlt1tMoXJZPwFydkKMds/z1ZnQY=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-filemanager = pyself.buildPythonPackage rec {
              pname = "OctoPrint-FileManager";
              version = "0.1.6";
              src = self.fetchFromGitHub {
                owner = "Salandora";
                repo = "OctoPrint-FileManager";
                rev = "${version}";
                sha256 = "sha256-4znIdVjfU/PPoFXmHBAtp5vAxly0R/R24tGMVbiaiYk=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-dashboard = pyself.buildPythonPackage rec {
              pname = "OctoPrint-Dashboard";
              version = "1.19.12";
              src = self.fetchFromGitHub {
                owner = "j7126";
                repo = "OctoPrint-Dashboard";
                rev = "${version}";
                sha256 = "sha256-454/nAAFT2afr0GA+X6KgFOu1Zeey4CvLgw2bPE6aEc=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octolapse = pyself.buildPythonPackage rec {
              pname = "Octolapse";
              version = "0.4.5";
              src = self.fetchFromGitHub {
                owner = "FormerLurker";
                repo = "Octolapse";
                rev = "v${version}";
                sha256 = "sha256-2lxE+Nzwcf4hJYiQ+0RmUzU70ZDu2qQS7W8GU7JYlvQ=";
              };
              propagatedBuildInputs = [
                pysuper.octoprint
                pkgs.python311Packages.pillow
                pkgs.python311Packages.sarge
                pkgs.python311Packages.six
                pkgs.python311Packages.psutil
                pkgs.python311Packages.file-read-backwards
                pkgs.python311Packages.setuptools
                pkgs.python311Packages.awesome-slugify
              ];
              doCheck = false;
            };

            octoprint-slicerestimator = pyself.buildPythonPackage rec {
              pname = "OctoPrint-SlicerEstimator";
              version = "1.6.7";
              src = self.fetchFromGitHub {
                owner = "NilsRo";
                repo = "OctoPrint-SlicerEstimator";
                rev = "${version}";
                sha256 = "sha256-teN1W0dowM36cz7F18J32I+YCYAVdqrOpqTtTTppAeI=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-preheat = pyself.buildPythonPackage rec {
              pname = "octoprint-preheat";
              version = "0.8.0";
              src = self.fetchFromGitHub {
                owner = "marian42";
                repo = "octoprint-preheat";
                rev = "${version}";
                sha256 = "sha256-9c2HPU+eN/WlDnRVpLgVX/qcNKj3XP+/BBZVpPxpl8I=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-uicustomizer = pyself.buildPythonPackage rec {
              pname = "OctoPrint-UICustomizer";
              version = "0.1.9.91";
              src = self.fetchFromGitHub {
                owner = "LazeMSS";
                repo = "OctoPrint-UICustomizer";
                rev = "${version}";
                sha256 = "sha256-RD8MDxjq22cdzeko6kC0ECBtIlh083Wbxeq8pEX1XFk=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-powerfailure = pyself.buildPythonPackage rec {
              pname = "OctoPrint-PowerFailure";
              version = "1.2.1";
              src = self.fetchFromGitHub {
                owner = "pablogventura";
                repo = "OctoPrint-PowerFailure";
                rev = "${version}";
                sha256 = "sha256-9w7zwdnzbYdtsQyOogSgmDkh48XxYfOTo8IuuJk+KKU=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-printtimegenius = pyself.buildPythonPackage rec {
              pname = "OctoPrint-PrintTimeGenius";
              version = "2.3.3";
              src = self.fetchFromGitHub {
                owner = "eyal0";
                repo = "OctoPrint-PrintTimeGenius";
                rev = "${version}";
                sha256 = "sha256-hqm8RShCNpsVbrVXquat5VXqcVc7q5tn5+7Ipqmaw4U=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-spoolmanager = pyself.buildPythonPackage rec {
              pname = "OctoPrint-SpoolManager";
              version = "1.7.4";
              src = self.fetchFromGitHub {
                owner = "WildRikku";
                repo = "OctoPrint-SpoolManager";
                rev = "${version}";
                sha256 = "sha256-hstzXlrDTOButqfyn7qDX9ZAT4DjhfMMhfUp1EuBAmw=";
              };
              propagatedBuildInputs = [
                pkgs.python311Packages.peewee
                pkgs.python311Packages.qrcode
                pkgs.python311Packages.pillow
                pysuper.octoprint
              ];
              doCheck = false;
            };

            # cura thumbnails
            octoprint-ultimakerformatpackage = pyself.buildPythonPackage rec {
              pname = "OctoPrint-UltimakerFormatPackage";
              version = "1.0.2";
              src = self.fetchFromGitHub {
                owner = "jneilliii";
                repo = "octoprint-ultimakerformatpackage";
                rev = "${version}";
                sha256 = "sha256-EvD3apeFV4WbeCdxBwFOtv4Luaid7RojQg6XYUTY2NQ=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };


            octoprint-prusaslicerthumbnails = pyself.buildPythonPackage rec {
              pname = "OctoPrint-PrusaSlicerThumbnails";
              version = "1.0.7";
              src = self.fetchFromGitHub {
                owner = "jneilliii";
                repo = "OctoPrint-PrusaSlicerThumbnails";
                rev = "${version}";
                sha256 = "sha256-waNCTjAZwdBfhHyJCG2La7KTnJ8MDVuX1JLetFB5bS4=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-tplinksmartplug = pyself.buildPythonPackage rec {
              pname = "OctoPrint-TPLinkSmartplug";
              version = "1.0.3";
              src = self.fetchFromGitHub {
                owner = "jneilliii";
                repo = "OctoPrint-TPLinkSmartplug";
                rev = "${version}";
                sha256 = "sha256-WzCFB0SUypwfAwwRcma9HRSfykZ1favqvwP53LgaGtY=";
              };
              propagatedBuildInputs = [
                pysuper.octoprint
                pkgs.python311Packages.uptime
              ];
              doCheck = false;
            };

            octoprint-printjobhistory = pyself.buildPythonPackage rec {
              pname = "OctoPrint-PrintJobHistory";
              version = "1.17.2";
              src = self.fetchFromGitHub {
                owner = "dojohnso";
                repo = "OctoPrint-PrintJobHistory";
                rev = "${version}";
                sha256 = "sha256-DBogfBGWW+UzLLssegWxH/8nYV9pCOZ8Em2K2HK/ocI=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            octoprint-excluderegion = pyself.buildPythonPackage rec {
              pname = "OctoPrint-ExcludeRegionPlugin";
              version = "0.3.2";
              src = self.fetchFromGitHub {
                owner = "bradcfisher";
                repo = "OctoPrint-ExcludeRegionPlugin";
                rev = "${version}";
                sha256 = "sha256-YS67lq7Y15EXuJxpZ9VE0PsveYmtIEzRMHRn1GNMJBU=";
              };
              propagatedBuildInputs = [ pysuper.octoprint ];
              doCheck = false;
            };

            # octoprint-themeify = pyself.buildPythonPackage rec {
            #   pname = "OctoPrint-Themeify";
            #   version = "1.2.2";
            #   src = self.fetchFromGitHub {
            #     owner = "Birkbjo";
            #     repo = "OctoPrint-Themeify";
            #     rev = "v${version}";
            #     sha256 = "sha256-om9IUSmxU8y0x8DrodW1EU/pilAN3+PbtYck6KfROEg=";
            #   };
            #   propagatedBuildInputs = [ pysuper.octoprint ];
            #   doCheck = false;
            # };
          };
        };
      })
    ];
  };
}
