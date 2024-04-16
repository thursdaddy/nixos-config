{ pkgs, lib, config, inputs, ... }:
with lib;
let

  cfg = config.mine.tools.sops;
  user = config.mine.user;

in
{
  options.mine.tools.sops = {
    enable = mkEnableOption "Enable sops";
  };

  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      sops
    ];

    sops = {
      defaultSopsFile = (inputs.secrets.packages.${pkgs.system}.secrets + "/encrypted/secrets.yaml");
      age.keyFile = "${user.homeDir}/.config/sops/age/keys.txt";
      secrets.tailscale_auth_key = { };
    };
  };
}
