{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.docker;

in
{
  options.mine.services.docker = {
    enable = mkEnableOption "Docker desktop";
  };

  config = mkIf cfg.enable {
    homebrew.casks = [ "docker-desktop" ];
  };
}
