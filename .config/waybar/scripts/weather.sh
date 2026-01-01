#!/bin/bash
# Get weather for Obruchevsky District, Moscow

LOG_FILE="/tmp/weather_debug.log"

# Debug logging
echo "$(date): Script started" >> "$LOG_FILE"

# Set a timeout for curl to prevent hanging
WEATHER=$(curl -s --max-time 15 "https://wttr.in/Obruchevsky+District,Moscow?format=%t")
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ] && [ -n "$WEATHER" ]; then
    echo "$(date): Success, weather is $WEATHER" >> "$LOG_FILE"
    echo "$WEATHER"
else
    echo "$(date): Failed. Exit code: $EXIT_CODE. Weather: $WEATHER" >> "$LOG_FILE"
    echo "N/A"
fi