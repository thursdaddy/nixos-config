{
  lib,
  config,
  inputs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.nixvim;

in
{
  options.mine.cli-tools.nixvim = {
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
