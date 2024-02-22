{ inputs, lib, config, ... }:
with lib;
let
  cfg = config.mine.zsh;

  in {
    config = mkIf cfg.enable {
      programs.zsh.enable = true;
    };

}
