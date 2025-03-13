{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let

  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  inherit (lib.thurs) mkOpt mkOpt_;
  cfg = config.mine.cli-tools.sops;

  ssm_systemd_config = mkIf cfg.ageKeyFile.ageKeyInSSM.enable {
    Environment = "SOPS_AGE_KEY_FILE=${cfg.ageKeyFile.path}";
    ExecStartPre = ssm_systemd_script + "/bin/get-age-key-from-ssm";
  };
  ssm_systemd_script = pkgs.writeShellApplication {
    name = "get-age-key-from-ssm";
    runtimeInputs = with pkgs; [
      awscli2
      coreutils
      gnused
    ];
    text = ''
      AGE_KEY=$(aws ssm get-parameter --region ${cfg.ageKeyFile.ageKeyInSSM.region} --no-cli-pager --name ${cfg.ageKeyFile.ageKeyInSSM.paramName} --with-decryption --query "Parameter.Value" | sed 's/\"//g')
      echo "$AGE_KEY" > ${cfg.ageKeyFile.path}
    '';
  };

in
{
  options.mine.cli-tools.sops = {
    enable = mkEnableOption "Enable sops";
    defaultSopsFile = mkOpt_ types.path "Default sops file used for all secrets.";
    ageKeyFile = mkOption {
      default = { };
      description = "ageKeyFile config";
      type = types.submodule {
        options = {
          path = mkOpt (types.nullOr types.path) null "Path to age key file used for sops decryption.";
          ageKeyInSSM = mkOption {
            default = { };
            description = "If age.key is in SSM";
            type = types.submodule {
              options = {
                enable = mkOpt types.bool false "Runs systemd service to pull key from SSM Parameter store";
                paramName = mkOpt (types.nullOr types.path) null "SSM Parameter name containing age key";
                region = mkOpt (types.enum [
                  "us-west-2"
                  "us-east-1"
                ]) "us-east-1" "AWS region for SSM parameter";
              };
            };
          };
        };
      };
    };
    requires = mkOption {
      default = { };
      description = "Things that are needed for SOPS";
      type = types.submodule {
        options = {
          network =
            mkOpt types.bool false
              "Decrypt after network is started, for network required keys like KMS.";
          unlock = mkOpt types.bool false "Decrypt after logging, or ZFS volumes have been decrypted";
        };
      };
    };
  };

  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];

    sops = {
      inherit (config.mine.cli-tools.sops) defaultSopsFile;
      age.keyFile = config.mine.cli-tools.sops.ageKeyFile.path;
    };

    systemd.services.decrypt-sops-after-network =
      mkIf (cfg.requires.network || cfg.ageKeyFile.ageKeyInSSM.enable)
        {
          description = "Decrypt SOPS secrets after network is established";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          requires = [ "network-online.target" ];
          serviceConfig = ssm_systemd_config // {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "3s";
          };
          script = config.system.activationScripts.setupSecrets.text;
        };

    systemd.services.decrypt-sops-after-login = mkIf cfg.requires.unlock {
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
}
