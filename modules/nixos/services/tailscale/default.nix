{ lib, pkgs, config, inputs, ... }:
with lib;
with lib.thurs;
let

  cfg = config.mine.services.tailscale;
  inherit (config.mine.cli-tools) sops;

in
{
  options.mine.services.tailscale = {
    enable = mkEnableOption "Enable Tailscale";
    authKeyFile = mkOpt (types.nullOr types.path) null "authKeyFile path";
    useRoutingFeatures = mkOpt (types.enum [ "none" "client" "server" "both" ]) "none" "Tailscale routingFeatures";
    extraUpFlags = mkOpt (types.listOf types.str) [ ] "Tailscale up flags";
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs.unstable.tailscale;
      openFirewall = true;
      authKeyFile = mkIf sops.enable config.sops.secrets."tailscale/AUTH_KEY".path;
      inherit (config.mine.services.tailscale) useRoutingFeatures;
      inherit (config.mine.services.tailscale) extraUpFlags;
    };

    sops.secrets."tailscale/AUTH_KEY" = mkIf sops.enable {
      sopsFile = inputs.nixos-thurs.packages.${pkgs.system}.mySecrets + "/encrypted/secrets.yaml";
    };

    systemd.services.tailscaled-autoconnect-reload = mkIf (sops.requires.network || sops.ageKeyFile.ageKeyInSSM.enable) {
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
