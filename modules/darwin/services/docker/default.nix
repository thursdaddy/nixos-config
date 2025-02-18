{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.docker;

in
{
  options.mine.cli-tools.docker = {
    enable = mkEnableOption "Docker desktop";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "docker" ];
  };
}
