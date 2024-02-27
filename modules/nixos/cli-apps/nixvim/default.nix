{ lib, config, pkgs, inputs,  ... }:
with lib;
with lib.thurs;
let

cfg = config.mine.nixos.nixvim;

in {
  options.mine.nixos.nixvim = {
    enable = mkEnableOption "NixVim";
  };

  imports = [
    inputs.nixvim.nixosModules.nixvim
      ./import.nix
  ];

  config = mkIf cfg.enable {

    programs.nixvim = {
      enable = true;
      vimAlias = true;
    };
  };

}
