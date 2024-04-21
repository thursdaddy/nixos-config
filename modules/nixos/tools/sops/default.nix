{ pkgs, lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.tools.sops;

in
{
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
    ageKeyFile = mkOpt (types.nullOr types.path) null "Path to age key file used for sops decryption.";
    requiresNetwork = mkOpt types.bool false "Decrypt after network is started, for network required keys like KMS.";
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

    systemd.services.decrypt-sops-after-network = mkIf cfg.requiresNetwork {
      description = "Decrypt sops secrets after network is established for KMS Encryped keys";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Restart = "on-failure";
        RestartSec = "2s";
      };
      script = config.system.activationScripts.setupSecrets.text;
    };
  };
}
