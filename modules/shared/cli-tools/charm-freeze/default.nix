{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.charm-freeze;

in
{
  options.mine.cli-tools.charm-freeze = {
    enable = mkEnableOption "Create images of your code";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      charm-freeze
    ];
  };
}
