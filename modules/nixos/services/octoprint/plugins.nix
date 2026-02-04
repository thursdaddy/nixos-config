{ pkgs, ... }:
{
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
            pyproject = true;
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
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.pillow

            ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
          };

          octoprint-homeassistant = pyself.buildPythonPackage rec {
            pname = "OctoPrint-HomeAssistant";
            version = "3.7.0";
            src = self.fetchFromGitHub {
              owner = "cmroche";
              repo = "OctoPrint-HomeAssistant";
              rev = "${version}";
              sha256 = "sha256-R6ayI8KHpBSR2Cnp6B2mKdJGHaxTENkOKvbvILLte2E=";
            };
            propagatedBuildInputs = [
              pysuper.octoprint
            ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
          };

          octoprint-costestimation = pyself.buildPythonPackage rec {
            pname = "OctoPrint-CostEstimation";
            version = "3.5.2";
            src = self.fetchFromGitHub {
              owner = "Hillshum";
              repo = "Octoprint-CostEstimation";
              rev = "${version}";
              sha256 = "sha256-SdVPVWCzw+PYmitkOF4fTc9GpQoH+maT8lvES//Fk4Y=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
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
            pyproject = true;
          };

          timelapse = pyself.buildPythonPackage rec {
            pname = "OctoPrint-TimeLapsePlus";
            version = "1.4.1";
            src = self.fetchFromGitHub {
              owner = "cmuche";
              repo = "octoprint-timelapseplus";
              rev = "v${version}";
              sha256 = "sha256-myyeM1wUYo0yrvkmnV6Xl5ThIl71olSlkOliYT/Rg/E=";
            };
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.pillow
              pkgs.python312Packages.deepdiff
            ];
            doCheck = false;
            pyproject = true;
            dontCheckRuntimeDeps = true;
          };

          # TODO: this is broken in 24.11 due to missing distutils since python 3.12 no longer packages by default
          # https://github.com/FormerLurker/Octolapse/issues/957
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
            ];
            doCheck = false;
            pyproject = true;
          };

          octoprint-slicerestimator = pyself.buildPythonPackage rec {
            pname = "OctoPrint-SlicerEstimator";
            version = "1.6.8";
            src = self.fetchFromGitHub {
              owner = "NilsRo";
              repo = "OctoPrint-SlicerEstimator";
              rev = "${version}";
              sha256 = "sha256-dftgYxyLb05mWGuAri63ocHWnoDHvjxFGcWcnW3x/ks=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
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
            pyproject = true;
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
            pyproject = true;
          };

          octoprint-printtimegenius = pyself.buildPythonPackage rec {
            pname = "OctoPrint-PrintTimeGenius";
            version = "2.3.4";
            src = self.fetchFromGitHub {
              owner = "eyal0";
              repo = "OctoPrint-PrintTimeGenius";
              rev = "${version}";
              sha256 = "sha256-dWBhP2QiOVJaeyE1v8tpbxD88Ox5Z2NxVzJkcpto2W0=";
            };
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.standard-imghdr
            ];
            doCheck = false;
            pyproject = true;
          };

          # https://github.com/WildRikku/OctoPrint-SpoolManager/releases
          octoprint-spoolmanager = pyself.buildPythonPackage rec {
            pname = "OctoPrint-SpoolManager";
            version = "1.7.7";
            src = self.fetchFromGitHub {
              owner = "WildRikku";
              repo = "OctoPrint-SpoolManager";
              rev = "${version}";
              sha256 = "sha256-FsBI2Gzd/sYuU6rfaI0zJGk6k/YvmYirYXJivBSC474=";
            };
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.peewee
              pkgs.python312Packages.qrcode
              pkgs.python312Packages.pillow
              pkgs.python312Packages.future
            ];
            build-system = [ pkgs.python312Packages.setuptools ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
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
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.pillow
            ];
            doCheck = false;
            pyproject = true;
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
              pkgs.python312Packages.uptime
            ];
            doCheck = false;
            pyproject = true;
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
            propagatedBuildInputs = [
              pysuper.octoprint
              pkgs.python312Packages.pillow
              pkgs.python312Packages.peewee
              pkgs.python312Packages.sarge
              pkgs.python312Packages.six
              pkgs.python312Packages.psutil
              pkgs.python312Packages.file-read-backwards
              pkgs.python312Packages.setuptools
              pkgs.python312Packages.awesome-slugify
              pkgs.python312Packages.future
            ];
            doCheck = false;
            pyproject = true;
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
            pyproject = true;
          };

          # octoprint-multicam = pyself.buildPythonPackage rec {
          #   pname = "OctoPrint-MultiCam";
          #   version = "0.4.2";
          #   src = self.fetchFromGitHub {
          #     owner = "mikedmor";
          #     repo = "OctoPrint_MultiCam";
          #     rev = "${version}";
          #     sha256 = "sha256-bqYTPCy3evmOahTZMWgfDeBRNwqerW9nR6lrumgqGPU=";
          #   };
          #   propagatedBuildInputs = [ pysuper.octoprint ];
          #   doCheck = false;
          #   pyproject = true;
          # };

          octoprint-octolight-home-assistant = pyself.buildPythonPackage rec {
            pname = "OctoPrint-Octolight-Home-Assistant";
            version = "0.2.2";
            src = self.fetchFromGitHub {
              owner = "mark-bloom";
              repo = "OctoLight_Home-Assistant";
              rev = "${version}";
              sha256 = "sha256-m6eOlMM2SqH0cyTKa23OU3mfGmMPjNPX/lOUwZOrLAY=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
            pyproject = true;
          };
        };
      };
    })
  ];
}
