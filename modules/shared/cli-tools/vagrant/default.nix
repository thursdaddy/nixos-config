{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.cli-tools.vagrant;

in
{
  options.mine.cli-tools.vagrant = {
    enable = mkEnableOption "Enable Vagrant";
  };

  config = mkIf cfg.enable {
    nixpkgs.config.allowUnfreePredicate =
      pkg:
      builtins.elem (lib.getName pkg) [
        "vagrant"
      ];

    environment.systemPackages = [
      pkgs.vagrant
    ];
  };
}
