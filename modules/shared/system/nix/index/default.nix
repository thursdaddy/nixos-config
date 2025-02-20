{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.nix.index;

in
{
  options.mine.system.nix.index = {
    enable = mkEnableOption "Enable nix-index";
  };

  config = mkIf cfg.enable {
    programs.nix-index.enable = true;
  };
}
