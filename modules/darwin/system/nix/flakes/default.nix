{ lib, config, ... }:
let

  inherit (lib) mkIf types;
  inherit (lib.thurs) mkOpt;
  cfg = config.mine.system.nix.flakes;

in
{
  options.mine.system.nix.flakes = {
    enable = mkOpt types.bool true "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix = {
      extraOptions = ''
        experimental-features = nix-command flakes
      '';
    };

    programs.nix-index.enable = false;
  };
}
