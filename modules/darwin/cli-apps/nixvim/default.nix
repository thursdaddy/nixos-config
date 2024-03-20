{ lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.cli-apps.nixvim;

in {
  options.mine.cli-apps.nixvim = {
    enable = mkEnableOption "Install NixVim";
  };

  imports = [
    inputs.nixvim.nixDarwinModules.nixvim
    ../../../nixos/cli-apps/nixvim/import.nix
  ];

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      vimAlias = true;
    };
  };
}
