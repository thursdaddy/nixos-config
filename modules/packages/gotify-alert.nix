_: {
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    {
      packages."gotify-alert" = pkgs.writeShellApplication {
        name = "_gotify-alert";
        runtimeInputs = with pkgs; [
          curl
          jq
          nettools
          coreutils
        ];
        text = ''
          set -e

          ####################################
          # ARGUMENT PASSED FROM SYSTEMD %I #
          ####################################
          SERVICE_NAME=$1

          ############################################################
          # LINK BACK TO LOGS IN GRAFANA INCLUDING PROPER TIME-RANGE #
          ############################################################
          GRAFANA_URL="https://grafana.thurs.pw"
          LOKI_UID="eefo8y8lxalfkc"
          NOW=$(date +%s)
          FROM=$(( (NOW - 2700) * 1000 ))
          TO=$(( (NOW + 900) * 1000 ))

          EXPLORE_STATE=$(jq -n \
            --arg uid "$LOKI_UID" \
            --arg q "{unit=\"$SERVICE_NAME.service\"}" \
            --arg from "$FROM" \
            --arg to "$TO" \
            '{
              datasource: $uid,
              queries: [{ refId: "A", expr: $q, mapper: "logs" }],
              range: { from: $from, to: $to }
            }')

          ENCODED_STATE=$(jq -nr --arg json "$EXPLORE_STATE" '$json | @uri')
          LOGS_URL="$GRAFANA_URL/explore?left=$ENCODED_STATE"

          #################################
          # CONSTRUCT MESSAGE AND PAYLOAD #
          #################################
          HOSTNAME=$(hostname)
          TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
          RAW_MESSAGE=" **Status:** Failed

          **Host:** $HOSTNAME

          **Time:** $TIMESTAMP

          [View in Grafana]($LOGS_URL)
          "

          PAYLOAD=$(jq -n \
            --arg title "🚨 $SERVICE_NAME 🚨" \
            --arg msg "$RAW_MESSAGE" \
            '{
              title: $title,
              message: $msg,
              priority: 8,
              extras: {
                "client::display": {
                  "contentType": "text/markdown"
                }
              }
            }')

          curl \
            -X POST "$GOTIFY_URL/message?token=$GOTIFY_APP_TOKEN" \
            -H "Content-Type: application/json" \
            -d "$PAYLOAD"
        '';
      };
    };
}
