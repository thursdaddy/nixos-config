{ lib, config, ... }:
let

  inherit (lib) mkIf;
  inherit (config.mine) user;

in
{
  config = mkIf user.ghToken.enable {
    nix.extraOptions = ''
      !include ${config.sops.secrets."github/TOKEN".path}
    '';

    sops.secrets."github/TOKEN" = {
      mode = "0440";
      owner = "${user.name}";
    };
  };
}
