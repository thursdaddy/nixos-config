{ lib, config, pkgs, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.cli-apps.nixvim;

in
{
  options.mine.cli-apps.nixvim = {
    enable = mkEnableOption "NixVim";
  };

  imports = [
    inputs.nixvim.nixosModules.nixvim
    ../../../nixvim/import.nix
  ];

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      vimAlias = true;
    };
  };

}
