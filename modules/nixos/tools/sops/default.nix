{ pkgs, lib, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.tools.sops;

in
{
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
    defaultSopsFile = mkOpt types.path "" "Default Sops file used for all secrets";
    ageKeyFile = mkOpt (types.nullOr types.path) null "Path to age key file used for sops decryption.";
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
  };
}
