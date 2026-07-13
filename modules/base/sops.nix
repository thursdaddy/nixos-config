{
  inputs,
  ...
}:
{
  flake.modules.generic.base =
    {
      lib,
      pkgs,
      ...
    }:
    {
      options.mine.base.sops = {
        defaultSopsFile = lib.mkOption {
          description = "Default sops file used for all secrets.";
          type = lib.types.path;
          default =
            inputs.nixos-thurs.packages.${pkgs.stdenv.hostPlatform.system}.mySecrets
            + "/encrypted/secrets.yaml";
        };
        requires = lib.mkOption {
          default = { };
          description = "Things that are needed for SOPS";
          type = lib.types.submodule {
            options = {
              network = lib.mkEnableOption "Decrypt after network is started, for network required keys like KMS.";
              unlock = lib.mkEnableOption "Decrypt after logging, or ZFS volumes have been decrypted";
            };
          };
        };
        ageKeyFile = lib.mkOption {
          default = { };
          description = "ageKeyFile config";
          type = lib.types.submodule {
            options = {
              path = lib.mkOption {
                description = "Path to age key file used for sops decryption.";
                type = (lib.types.nullOr lib.types.path);
                default = null;
              };
              ageKeyInGCP = lib.mkOption {
                description = "If age.key is in GCP Secret Manager";
                default = { };
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Runs systemd service to pull key from GCP Secret Manager";
                    secretName = lib.mkOption {
                      description = "GCP Secret name containing age key (e.g. sops-age-key)";
                      type = (lib.types.nullOr lib.types.str);
                      default = null;
                    };
                  };
                };
              };
              ageKeyInSSM = lib.mkOption {
                description = "If age.key is in SSM";
                default = { };
                type = lib.types.submodule {
                  options = {
                    enable = lib.mkEnableOption "Runs systemd service to pull key from SSM Parameter store";
                    paramName = lib.mkOption {
                      description = "SSM Parameter name containing age key";
                      type = (lib.types.nullOr lib.types.path);
                      default = null;
                    };
                    region = lib.mkOption {
                      type = (
                        lib.types.enum [
                          "us-west-2"
                          "us-east-1"
                        ]
                      );
                      default = "us-east-1";
                      description = "AWS region for SSM parameter";
                    };
                  };
                };
              };
            };
          };
        };
      };
    };

  flake.modules.nixos.base =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      ssm_systemd_script = pkgs.writeShellApplication {
        name = "get-age-key-from-ssm";
        runtimeInputs = with pkgs; [
          awscli2
          coreutils
          gnused
        ];
        text = ''
          set -x
          if [ ! -s "${config.sops.age.keyFile}" ]; then
            mkdir -p "$(dirname "${config.sops.age.keyFile}")"
            aws ssm get-parameter --endpoint-url https://ssm.us-west-2.api.aws --region ${config.mine.base.sops.ageKeyFile.ageKeyInSSM.region} --no-cli-pager --name ${config.mine.base.sops.ageKeyFile.ageKeyInSSM.paramName} --with-decryption --query "Parameter.Value" --output text > ${config.sops.age.keyFile}
          else
            echo "SOPS key already exists at ${config.sops.age.keyFile}, skipping SSM fetch."
          fi
        '';
      };

      gcp_systemd_script = pkgs.writeShellApplication {
        name = "get-age-key-from-gcp";
        runtimeInputs = with pkgs; [
          google-cloud-sdk
          coreutils
        ];
        text = ''
          set -x
          if [ ! -s "${config.sops.age.keyFile}" ]; then
            mkdir -p "$(dirname "${config.sops.age.keyFile}")"
            gcloud secrets versions access latest --secret="${config.mine.base.sops.ageKeyFile.ageKeyInGCP.secretName}" > ${config.sops.age.keyFile}
          else
            echo "SOPS key already exists at ${config.sops.age.keyFile}, skipping GCP fetch."
          fi
        '';
      };
    in
    {
      imports = [
        inputs.sops-nix.nixosModules.sops
        inputs.nixos-thurs.nixosModules.configs
      ];

      config = {
        sops = {
          inherit (config.mine.base.sops) defaultSopsFile;
          age.keyFile = config.mine.base.sops.ageKeyFile.path;
        };

        environment = {
          systemPackages = with pkgs; [
            sops
          ];
        };

        systemd.services.decrypt-sops-after-network =
          lib.mkIf
            (config.mine.base.sops.requires.network || config.mine.base.sops.ageKeyFile.ageKeyInSSM.enable || config.mine.base.sops.ageKeyFile.ageKeyInGCP.enable)
            {
              description = "Decrypt SOPS secrets after network is established";
              wantedBy = [ "multi-user.target" ];
              after = [ "network-online.target" ];
              requires = [ "network-online.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                Restart = "on-failure";
                RestartSec = "3s";
              } // lib.optionalAttrs config.mine.base.sops.ageKeyFile.ageKeyInSSM.enable {
                Environment = [
                  "SOPS_AGE_KEY_FILE=${config.sops.age.keyFile}"
                  "AWS_CA_BUNDLE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                ];
                ExecStartPre = ssm_systemd_script + "/bin/get-age-key-from-ssm";
              } // lib.optionalAttrs config.mine.base.sops.ageKeyFile.ageKeyInGCP.enable {
                Environment = [
                  "SOPS_AGE_KEY_FILE=${config.sops.age.keyFile}"
                ];
                ExecStartPre = gcp_systemd_script + "/bin/get-age-key-from-gcp";
              };
              script = config.system.activationScripts.setupSecrets.text;
            };

        systemd.services.decrypt-sops-after-login = lib.mkIf config.mine.base.sops.requires.unlock {
          description = "Decrypt SOPS secrets after disk has been unlocked";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          requires = [ "network-online.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "3s";
          };
          script = config.system.activationScripts.setupSecrets.text;
        };
      };
    };

  flake.modules.darwin.base =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        inputs.sops-nix.darwinModules.sops
        inputs.nixos-thurs.nixosModules.configs
      ];

      config = {
        sops = {
          inherit (config.mine.base.sops) defaultSopsFile;
          age.keyFile = config.mine.base.sops.ageKeyFile.path;
        };

        environment.systemPackages = with pkgs; [
          sops
        ];
      };
    };
}
