{
  lib,
  pkgs,
  config,
  inputs,
  ...
}:
let

  inherit (lib) mkEnableOption mkIf types;
  inherit (lib.thurs) mkOpt;
  inherit (config.mine.cli-tools) sops;
  cfg = config.mine.services.tailscale;

in
{
  options.mine.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
    authKeyFile = mkOpt types.path config.sops.secrets."tailscale/AUTH_KEY".path "authKeyFile path";
    useRoutingFeatures = mkOpt (types.enum [
      "none"
      "client"
      "server"
      "both"
    ]) "none" "Tailscale routingFeatures";
    extraUpFlags = mkOpt (types.listOf types.str) [ ] "Tailscale up flags";
    extraSetFlags = mkOpt (types.listOf types.str) [ ] "Tailscale set flags";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      openFirewall = true;
      inherit (config.mine.services.tailscale) authKeyFile;
      inherit (config.mine.services.tailscale) useRoutingFeatures;
      inherit (config.mine.services.tailscale) extraUpFlags;
      inherit (config.mine.services.tailscale) extraSetFlags;
    };

    sops.secrets."tailscale/AUTH_KEY" = mkIf sops.enable {
      sopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
    };

    systemd.services.tailscaled-autoconnect-reload =
      mkIf (sops.requires.network || sops.ageKeyFile.ageKeyInSSM.enable)
        {
          description = "Restart tailscaled-autoconnect after secrets have been decrypted";
          after = [ "decrypt-sops-after-network.service" ];
          partOf = [ "decrypt-sops-after-network.service" ];
          wantedBy = [ "multi-user.target" ];
          preStart = "${pkgs.coreutils}/bin/sleep 1";
          serviceConfig = {
            Type = "oneshot";
          };
          script = ''
            ${config.systemd.package}/bin/systemctl restart tailscaled-autoconnect
          '';
        };
  };
}
