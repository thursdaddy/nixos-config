_: {
  flake.modules.nixos.services =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.services.keepalived;

      mkNotifyScript = name: extraCommands: pkgs.writeShellScript "keepalived-notify-${name}.sh" ''
        TYPE=$1
        NAME=$2
        STATE=$3

        # Gotify notification
        if [ -f ${config.sops.secrets."gotify/URL".path} ] && [ -f ${config.sops.secrets."gotify/token/KEEPALIVED".path} ]; then
          GOTIFY_URL=$(cat ${config.sops.secrets."gotify/URL".path})
          GOTIFY_TOKEN=$(cat ${config.sops.secrets."gotify/token/KEEPALIVED".path})

          PAYLOAD=$( ${pkgs.jq}/bin/jq -n \
            --arg title "Keepalived: $NAME State Changed" \
            --arg msg "Host **${config.networking.hostName}** transitioned to state **$STATE** for instance **$NAME**." \
            '{
              title: $title,
              message: $msg,
              priority: 6,
              extras: {
                "client::display": {
                  "contentType": "text/markdown"
                }
              }
            }' )

          ${pkgs.curl}/bin/curl -s -X POST "$GOTIFY_URL/message" \
            -H "X-Gotify-Key: $GOTIFY_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD" || true
        fi

        ${extraCommands}
      '';
    in
    {
      options.mine.services.keepalived = {
        enable = lib.mkEnableOption "Enable Keepalived VRRP for High Availability";

        # Legacy / default instance settings (for backwards compatibility)
        state = lib.mkOption {
          type = lib.types.enum [ "MASTER" "BACKUP" ];
          default = "BACKUP";
          description = "Initial VRRP state. MASTER will hold the IP initially.";
        };
        priority = lib.mkOption {
          type = lib.types.int;
          default = 100;
          description = "VRRP priority (higher wins the election).";
        };
        virtualIp = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "The Virtual IP to share (e.g., 192.168.10.53).";
        };
        interface = lib.mkOption {
          type = lib.types.str;
          default = "eth0";
          description = "The network interface to bind to (e.g. eno1, eth0).";
        };
        routerId = lib.mkOption {
          type = lib.types.int;
          default = 51;
          description = "VRRP Virtual Router ID (must be the same across all HA nodes).";
        };

        # Generalized multi-instance options
        instances = lib.mkOption {
          description = "High-availability VRRP instances.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                state = lib.mkOption {
                  type = lib.types.enum [ "MASTER" "BACKUP" ];
                  default = "BACKUP";
                };
                priority = lib.mkOption {
                  type = lib.types.int;
                  default = 100;
                };
                virtualIp = lib.mkOption {
                  type = lib.types.str;
                  description = "The Virtual IP to share (e.g. 192.168.10.54/24).";
                };
                interface = lib.mkOption {
                  type = lib.types.str;
                  description = "Physical network interface.";
                };
                routerId = lib.mkOption {
                  type = lib.types.int;
                  description = "Virtual Router ID (must match across hosts).";
                };
                trackScripts = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };
                notifyMaster = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Script/commands to run when transitioning to MASTER.";
                };
                notifyBackup = lib.mkOption {
                  type = lib.types.nullOr lib.types.str;
                  default = null;
                  description = "Script/commands to run when transitioning to BACKUP/FAULT.";
                };
                noPreempt = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Disable preemption when a higher priority node comes online.";
                };
              };
            }
          );
        };

        vrrpScripts = lib.mkOption {
          description = "Custom health checking scripts.";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                script = lib.mkOption { type = lib.types.str; };
                interval = lib.mkOption { type = lib.types.int; default = 2; };
                weight = lib.mkOption { type = lib.types.int; default = -10; };
                user = lib.mkOption { type = lib.types.str; default = "root"; };
              };
            }
          );
        };
      };

      config = lib.mkIf cfg.enable {
        # Allow VRRP protocol (IP protocol 112) through the firewall
        networking.firewall.extraCommands = ''
          iptables -I INPUT -p vrrp -j ACCEPT
        '';

        sops.secrets = {
          "gotify/URL" = { };
          "gotify/token/KEEPALIVED" = { };
        };

        services.keepalived = {
          enable = true;
          vrrpScripts = lib.mkMerge [
            (lib.optionalAttrs (cfg.virtualIp != null) {
              check_blocky = {
                script = "${pkgs.systemd}/bin/systemctl is-active --quiet blocky.service";
                interval = 2;
                weight = -60;
                user = "root";
              };
            })
            (lib.mapAttrs (name: scriptCfg: {
              inherit (scriptCfg) script interval weight user;
            }) cfg.vrrpScripts)
          ];

          vrrpInstances = lib.mkMerge [
            (lib.optionalAttrs (cfg.virtualIp != null) {
              "dns_ha" = {
                interface = cfg.interface;
                state = cfg.state;
                priority = cfg.priority;
                virtualRouterId = cfg.routerId;
                virtualIps = [
                  { addr = cfg.virtualIp; }
                ];
                trackScripts = [ "check_blocky" ];
                extraConfig = ''
                  notify "${mkNotifyScript "dns_ha" "exit 0"}"
                '';
              };
            })
            (lib.mapAttrs (name: instCfg: {
              interface = instCfg.interface;
              state = instCfg.state;
              priority = instCfg.priority;
              virtualRouterId = instCfg.routerId;
              virtualIps = [
                { addr = instCfg.virtualIp; }
              ];
              trackScripts = instCfg.trackScripts;
              noPreempt = instCfg.noPreempt;
              extraConfig =
                let
                  notifyScript = mkNotifyScript name ''
                    case $STATE in
                      "MASTER")
                        ${lib.optionalString (instCfg.notifyMaster != null) instCfg.notifyMaster}
                        exit 0
                        ;;
                      "BACKUP"|"FAULT")
                        ${lib.optionalString (instCfg.notifyBackup != null) instCfg.notifyBackup}
                        exit 0
                        ;;
                      *)
                        exit 0
                        ;;
                    esac
                  '';
                in
                ''
                  notify "${notifyScript}"
                '';
            }) cfg.instances)
          ];
        };

        environment.etc =
          let
            alloyJournal = lib.thurs.mkAlloyJournal {
              name = "keepalived";
            };
          in
          builtins.listToAttrs [
            alloyJournal
          ];
      };
    };
}
