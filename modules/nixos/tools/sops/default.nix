{ pkgs, lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.tools.sops;

  ssm_systemd_config = mkIf cfg.ageKeyInSSM {
    Environment = "SOPS_AGE_KEY_FILE=${cfg.ageKeyFile}";
    ExecStartPre = (ssm_systemd_script + "/bin/get-age-key-from-ssm");
  };
  ssm_systemd_script = pkgs.writeShellApplication {
    name = "get-age-key-from-ssm";
    runtimeInputs = with pkgs; [ awscli2 coreutils gnused ];
    text = ''
      agekey=$(aws ssm get-parameter --no-cli-pager --name ${cfg.ageKeyFile} --with-decryption --query "Parameter.Value" | sed 's/\"//g')
      echo "$agekey" > ${cfg.ageKeyFile}
    '';
  };

in
{
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
    ageKeyFile = mkOpt (types.nullOr types.path) null "Path to age key file used for sops decryption.";
    ageKeyInSSM = mkEnableOption "Runs systemd service to pull key from SSM Parameter store";
    requiresNetwork = mkOpt types.bool false "Decrypt after network is started, for network required keys like KMS.";
    requiresUnlock = mkOpt types.bool false "Decrypt after logging in. ";
    defaultSopsFile = mkOption {
      type = types.path;
      description = ''
        Default sops file used for all secrets.
      '';
    };
  };

  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];

    sops = {
      defaultSopsFile = config.mine.tools.sops.defaultSopsFile;
      age.keyFile = config.mine.tools.sops.ageKeyFile;
    };

    systemd.services.decrypt-sops-after-network = mkIf (cfg.requiresNetwork || cfg.ageKeyInSSM) {
      description = "Decrypt SOPS secrets after network is established";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = (ssm_systemd_config // {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "3s";
      });
      script = config.system.activationScripts.setupSecrets.text;
    };

    systemd.services.decrypt-sops-after-login = mkIf cfg.requiresUnlock {
      description = "Decrypt SOPS secrets after disk has been unlocked";
      wantedBy = [ "default.target" ];
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
