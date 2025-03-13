{
  lib,
  config,
  pkgs,
  ...
}:
let

  inherit (lib) mkIf mkForce;

in
{
  config = mkIf (config.mine.user.shell.package == pkgs.fish) {
    # Fish shell enables this and it takes forever to build man-cache as a result
    # Unfortunately this is not an option in darwin so putting it in nixos modules instead of modules/shared/user/shell/fish config
    documentation.man.generateCaches = mkForce false;
  };
}
