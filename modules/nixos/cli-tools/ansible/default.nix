{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
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
