set -e

# Arguments passed from systemd %i
SERVICE_NAME=$1
HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

GRAFANA_URL="https://grafana.thurs.pw"
LOKI_UID="eefo8y8lxalfkc"  # Find this in your Loki datasource settings
# Dynamic alert time range
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

curl -s -S \
  -X POST "$GOTIFY_URL/message?token=$GOTIFY_APP_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD"
