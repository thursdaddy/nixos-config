{ lib, config, pkgs, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.services.r53-updater;

  r53-updater = pkgs.writeShellApplication {
    name = "r53-updater";
    runtimeInputs = with pkgs; [ awscli2 coreutils curl dig gawk ];

    text = ''
      export AWS_PAGER=""
      # Function to get current public IP address
      get_instance_ip() {
          curl -s icanhazip.com
      }

      # Function to get IP address currently assigned to a domain
      get_current_dns_record() {
          local domain="$1"
          dig +short "$domain"
      }

      # Function to get hosted zone ID for the root domain
      get_hosted_zone_id() {
          local domain="$1"
          aws route53 list-hosted-zones-by-name \
              --dns-name "$domain" \
              --query "HostedZones[0].Id" \
              --output text
      }

      # Function to update Route 53 record if IP has changed
      update_route53_record() {
          local new_ip="$1"
          local hosted_zone_id="$2"
          aws route53 change-resource-record-sets \
              --hosted-zone-id "$hosted_zone_id" \
              --change-batch "{
                  \"Changes\":[{
                      \"Action\":\"UPSERT\",
                      \"ResourceRecordSet\":{
                          \"Name\":\"$3\",
                          \"Type\":\"A\",
                          \"TTL\":300,
                          \"ResourceRecords\":[{\"Value\":\"$new_ip\"}]
                      }
                  }]
              }"
      }

      # Main script
      if [ "$#" -eq 0 ]; then
          echo "Usage: $0 <FQDN1> <FQDN2> ..."
          exit 1
      fi

      for fqdn in "$@"; do
          base_domain=$(echo "$fqdn" | awk -F'.' '{print $(NF-1)"."$NF}')
          instance_ip=$(get_instance_ip)
          dns_record=$(get_current_dns_record "$fqdn")
          hosted_zone_id=$(get_hosted_zone_id "$base_domain")

          if [ -z "$hosted_zone_id" ]; then
              echo "Failed to retrieve hosted zone ID for $fqdn"
              continue
          fi

          if [ "$instance_ip" != "$dns_record" ]; then
              echo "IP has changed for $fqdn. Updating Route 53 record."
              echo "Instance IP: $instance_ip"
              echo "Current DNS IP: $dns_record"
              update_route53_record "$instance_ip" "$hosted_zone_id" "$fqdn"
          else
              echo "IP has not changed for $fqdn. No action needed."
          fi
      done
    '';
  };
in
{
  options.mine.services.r53-updater = {
    enable = mkEnableOption "Enable AWS r53-updater";
  };

  config = mkIf cfg.enable {
    sops.secrets."r53-updater/domains_to_check" = { };

    environment.systemPackages = [
      r53-updater
    ];

    systemd.services.r53-updater = {
      description = "Route53 Updater - Check if Instance IP has changed and update Route53 accordingly";
      wantedBy = [ "multi-user.target" ];
      after = [ "network-online.target" ];
      requires = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        Restart = "on-failure";
        RestartSec = "5s";
      };
      script = "/run/current-system/sw/bin/r53-updater $(cat /run/secrets/r53-updater/domains_to_check)";
    };
  };
}
