{ lib, config, ... }:
with lib;
let
  inherit (config.mine) user;
in
{
  config = mkIf user.ghToken.enable {
    home-manager.users.${user.name} = {
      sops = {
        secrets."github/TOKEN" = { };
      };
    };

    nix.extraOptions = ''
      !include ${config.home-manager.users.${user.name}.sops.secrets."github/TOKEN".path}
    '';
  };
}
