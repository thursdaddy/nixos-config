{ lib, config, pkgs, ... }:
with lib;
let

  cfg = config.mine.cli-tools.ansible;

in
{
  options.mine.cli-tools.ansible = {
    enable = mkEnableOption "Enable ansible";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.ansible
    ];
  };
}
