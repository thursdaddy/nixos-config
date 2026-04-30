# shellcheck disable=SC1091
ENV_FILE="/run/secrets/rendered/waybar-geo.env"
# shellcheck disable=SC1090
source "$ENV_FILE"

# Split Caches
CURRENT_CACHE="/tmp/weather_current.json"
FORECAST_CACHE="/tmp/weather_forecast.json"
LOG="/tmp/weather_debug.log"

HA_URL="https://home.thurs.pw"
HA_SENSOR="sensor.temp_patio_temperature"
TOKEN_FILE="/run/secrets/rendered/waybar-hass.token"

NOW=$(date +%s)

# --- LOGGING SETUP ---
# Prevent the log from growing infinitely in RAM. If > 1000 lines, keep the latest 500.
if [ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 1000 ]; then
    tail -n 500 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
fi

echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] Action: '${1:-Waybar Tick}'" >> "$LOG"

# 1. Check Current Weather Cache (15 Mins / 900s)
if [ ! -f "$CURRENT_CACHE" ]; then
    echo "[CACHE] Current: Missing. Fetch required." >> "$LOG"
    FETCH_CURRENT=true
else
    CACHE_TIME_CURRENT=$(stat -c %Y "$CURRENT_CACHE")
    if (( NOW - CACHE_TIME_CURRENT > 900 )); then
        echo "[CACHE] Current: Expired (> 15m). Fetch required." >> "$LOG"
        FETCH_CURRENT=true
    else
        echo "[CACHE] Current: Valid. Serving from file." >> "$LOG"
        FETCH_CURRENT=false
    fi
fi

# 2. Check Forecast Cache (8 Hours / 28800s)
if [ ! -f "$FORECAST_CACHE" ]; then
    echo "[CACHE] Forecast: Missing. Fetch required." >> "$LOG"
    FETCH_FORECAST=true
else
    CACHE_TIME_FORECAST=$(stat -c %Y "$FORECAST_CACHE")
    if (( NOW - CACHE_TIME_FORECAST > 28800 )); then
        echo "[CACHE] Forecast: Expired (> 8h). Fetch required." >> "$LOG"
        FETCH_FORECAST=true
    else
        echo "[CACHE] Forecast: Valid. Serving from file." >> "$LOG"
        FETCH_FORECAST=false
    fi
fi

# 3. Execute Fetches Independently (Atomic Writes)
if [ "$FETCH_CURRENT" = "true" ]; then
    echo "[FETCH] Pulling Current Data from Open-Meteo API..." >> "$LOG"
    if curl -s --fail "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&current=temperature_2m,weather_code&temperature_unit=fahrenheit&timezone=America%2FPhoenix" > "${CURRENT_CACHE}.tmp" 2>> "$LOG"; then
        mv "${CURRENT_CACHE}.tmp" "$CURRENT_CACHE"
        echo "[FETCH] Current Data: Success" >> "$LOG"
    else
        echo "[ERROR] Current Data: FAILED (Keeping stale cache)" >> "$LOG"
    fi
fi

if [ "$FETCH_FORECAST" = "true" ]; then
    echo "[FETCH] Pulling Forecast Data from Open-Meteo API..." >> "$LOG"
    if curl -s --fail "https://api.open-meteo.com/v1/forecast?latitude=$LAT&longitude=$LON&daily=weather_code,temperature_2m_max,temperature_2m_min&temperature_unit=fahrenheit&timezone=America%2FPhoenix" > "${FORECAST_CACHE}.tmp" 2>> "$LOG"; then
        mv "${FORECAST_CACHE}.tmp" "$FORECAST_CACHE"
        echo "[FETCH] Forecast Data: Success" >> "$LOG"
    else
        echo "[ERROR] Forecast Data: FAILED (Keeping stale cache)" >> "$LOG"
    fi
fi

get_icon() {
    case $1 in
        0) echo "☀️" ;;
        1|2|3) echo "⛅" ;;
        45|48) echo "🌫️" ;;
        51|53|55|56|57|61|63|65|66|67) echo "🌧️" ;;
        71|73|75|77) echo "❄️" ;;
        80|81|82) echo "🌦️" ;;
        85|86) echo "🌨️" ;;
        95|96|99) echo "⛈️" ;;
        *) echo "🌡️" ;;
    esac
}

get_desc() {
    case $1 in
        0) echo "Clear" ;;
        1|2|3) echo "Partly Cloudy" ;;
        45|48) echo "Fog" ;;
        51|53|55|56|57) echo "Drizzle" ;;
        61|63|65|66|67) echo "Rain" ;;
        71|73|75|77) echo "Snow" ;;
        80|81|82) echo "Showers" ;;
        85|86) echo "Snow Showers" ;;
        95|96|99) echo "Thunderstorm" ;;
        *) echo "Unknown" ;;
    esac
}

# 4. Graceful failover if caches don't exist at all yet
if [ ! -f "$CURRENT_CACHE" ] || [ ! -f "$FORECAST_CACHE" ]; then
    echo "{\"text\": \"⏳ Offline\", \"tooltip\": \"Waiting for network connection...\"}"
    exit 0
fi

case "${1:-}" in
    --current)
        TEMP=$(jq -r '.current.temperature_2m' "$CURRENT_CACHE" | awk '{print int($1+0.5)}') 2>> "$LOG"
        HIGH=$(jq -r '.daily.temperature_2m_max[0]' "$FORECAST_CACHE" | awk '{print int($1+0.5)}') 2>> "$LOG"
        LOW=$(jq -r '.daily.temperature_2m_min[0]' "$FORECAST_CACHE" | awk '{print int($1+0.5)}') 2>> "$LOG"
        CODE=$(jq -r '.current.weather_code' "$CURRENT_CACHE") 2>> "$LOG"
        DESC=$(get_desc "$CODE")

        echo "[NOTIFY] Triggering Current Weather popup..." >> "$LOG"
        notify-send -a "Weather" "Current Conditions" "Temp: ${TEMP}°F\nHigh: ${HIGH}°F | Low: ${LOW}°F\n${DESC}" 2>> "$LOG"
        ;;

    --ha)
        echo "[FETCH] Pulling Home Assistant patio sensor..." >> "$LOG"
        if [ -f "$TOKEN_FILE" ]; then
            HA_TOKEN=$(cat "$TOKEN_FILE")
            HA_RAW=$(curl -s -f -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" "$HA_URL/api/states/$HA_SENSOR" || true) 2>> "$LOG"

            if [ -n "$HA_RAW" ]; then
                HA_TEMP=$(echo "$HA_RAW" | jq -r '.state' | awk '{print int($1+0.5)}')
                echo "[NOTIFY] Triggering HA Sensor popup..." >> "$LOG"
                notify-send -a "Home Assistant" "Live Sensor" "Patio: ${HA_TEMP}°F" 2>> "$LOG"
            else
                echo "[ERROR] Failed to fetch from HA API." >> "$LOG"
                notify-send -a "Home Assistant" "Error" "Failed to fetch from HA API." 2>> "$LOG"
            fi
        else
            echo "[ERROR] HA Token not found at $TOKEN_FILE" >> "$LOG"
            notify-send -a "Home Assistant" "Error" "Token not found at $TOKEN_FILE" 2>> "$LOG"
        fi
        ;;

    --forecast)
        ROW_ICONS=""
        ROW_DAYS=""
        ROW_TEMPS=""

        for i in {1..5}; do
            DATE=$(jq -r ".daily.time[$i]" "$FORECAST_CACHE")
            HIGH=$(jq -r ".daily.temperature_2m_max[$i]" "$FORECAST_CACHE" | awk '{print int($1+0.5)}')
            LOW=$(jq -r ".daily.temperature_2m_min[$i]" "$FORECAST_CACHE" | awk '{print int($1+0.5)}')
            CODE=$(jq -r ".daily.weather_code[$i]" "$FORECAST_CACHE")

            ICON=$(get_icon "$CODE")
            DAY=$(date -d "$DATE" +"%a")
            TEMP_STR="${LOW}/${HIGH}"

            WIDTH=$(( ${#TEMP_STR} + 2 ))
            ICON_WIDTH=$(( WIDTH + 1 ))

            ROW_ICONS+=$(printf "%-${ICON_WIDTH}s" "$ICON")
            ROW_DAYS+=$(printf "%-${WIDTH}s" "$DAY")
            ROW_TEMPS+=$(printf "%-${WIDTH}s" "$TEMP_STR")
        done

        MSG="<span font_family='monospace'>${ROW_ICONS}\n${ROW_DAYS}\n${ROW_TEMPS}</span>"

        echo "[NOTIFY] Triggering 5-Day Forecast popup..." >> "$LOG"
        notify-send -a "Weather" "5-Day Forecast" "$MSG" 2>> "$LOG"
        ;;

    *)
        OM_TEMP=$(jq -r '.current.temperature_2m' "$CURRENT_CACHE" | awk '{print int($1+0.5)}') 2>> "$LOG"
        CODE=$(jq -r '.current.weather_code' "$CURRENT_CACHE") 2>> "$LOG"
        ICON=$(get_icon "$CODE")
        DESC=$(get_desc "$CODE")

        HA_TEMP="--"
        if [ -f "$TOKEN_FILE" ]; then
            HA_TOKEN=$(cat "$TOKEN_FILE")
            HA_RAW=$(curl -s -f -H "Authorization: Bearer $HA_TOKEN" -H "Content-Type: application/json" "$HA_URL/api/states/$HA_SENSOR" || true) 2>> "$LOG"

            if [ -n "$HA_RAW" ]; then
                HA_VAL=$(echo "$HA_RAW" | jq -r '.state')
                if [[ "$HA_VAL" != "null" && "$HA_VAL" != "unavailable" && "$HA_VAL" != "unknown" ]]; then
                    HA_TEMP=$(echo "$HA_VAL" | awk '{print int($1+0.5)}')
                fi
            fi
        fi

        echo "[INFO] Handing off JSON to Waybar..." >> "$LOG"
        if [ "$HA_TEMP" != "--" ]; then
            echo "{\"text\": \"$ICON ${OM_TEMP}°F / ${HA_TEMP}°F\"}"
        else
            echo "{\"text\": \"$ICON ${OM_TEMP}°F\"}"
        fi
        ;;
esac
