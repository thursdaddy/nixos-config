{
  lib,
  config,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.nix.substituters;

in
{
  options.mine.system.nix.substituters = {
    enable = mkEnableOption "Enable Flakes";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://attic.thurs.pw/local?priority=10" ];
      trusted-public-keys = [ "local:N0zoKlOpv5HJk2ct5mtF+8mBa+cM+c7KeroG1mQ6e54=" ];
    };
  };
}
