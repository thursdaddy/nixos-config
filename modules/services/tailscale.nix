_: {
  flake.modules.nixos.services =
    {
      config,
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      name = "tailscale";
      cfg = config.mine.services.${name};
    in
    {
      options.mine.services.${name} = {
        enable = lib.mkOption {
          description = "Enable Tailscale";
          type = lib.types.bool;
          default = true;
        };

        authKeyFile = lib.mkOption {
          type = lib.types.path;
          default = config.sops.secrets."${cfg.sopsSecret}".path;
          description = "Path to the Tailscale auth key file";
        };

        sopsSecret = lib.mkOption {
          type = lib.types.str;
          default = "tailscale/AUTH_KEY";
          description = "Sops secret key for tailscale auth";
        };

        useRoutingFeatures = lib.mkOption {
          type = lib.types.enum [
            "none"
            "client"
            "server"
            "both"
          ];
          default = "client";
          description = ''
            Tailscale routingFeatures:
              server = exit node or subnet router
              client = use exit node or subnet router
          '';
        };

        extraUpFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "--accept-routes=true" ];
          description = ''
            Tailscale up flags:
              server = [
                "--advertise-routes=192.168.10.0/24"
                "--accept-routes=false"
              ];
              client = [
                "--accept-routes=true"
              ];
          '';
        };

        extraSetFlags = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Tailscale set flags";
        };
      };

      config = lib.mkIf cfg.enable {
        services.tailscale = {
          enable = true;
          package = pkgs.unstable.tailscale;
          openFirewall = true;
          inherit (cfg) authKeyFile;
          inherit (cfg) useRoutingFeatures;
          inherit (cfg) extraUpFlags;
          inherit (cfg) extraSetFlags;
        };

        sops.secrets."${cfg.sopsSecret}" = { };

        systemd.services.tailscaled-autoconnect-reload =
          lib.mkIf
            (config.mine.base.sops.requires.network || config.mine.base.sops.ageKeyFile.ageKeyInSSM.enable)
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

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              inherit name;
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
