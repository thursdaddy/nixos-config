{ lib, config, ... }:
with lib;
let

  cfg = config.mine.system.nix.unfree;

in
{
  options.mine.system.nix.unfree = {
    enable = mkEnableOption "Enable Unfree packages";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
  };

}
