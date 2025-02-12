{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.awscli;

in
{
  options.mine.cli-tools.awscli = {
    enable = mkEnableOption "Enable awscli";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.awscli2
    ];
  };
}
