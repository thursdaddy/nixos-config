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
    enable = mkEnableOption "Add substituters";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      trusted-substituters = [ "https://attic.thurs.pw/local?priority=10" ];
      trusted-public-keys = [ "local:itXoM4f8cbcC/kFOdbmj/P1mY5C9OICa+ociYA40j4E=" ];
    };
  };
}
