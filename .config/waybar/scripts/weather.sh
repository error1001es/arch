#!/bin/bash
# Get weather for Obruchevsky District, Moscow

LOG_FILE="/tmp/weather_debug.log"
CACHE_FILE="/tmp/weather_cache"
LOCATION="Obruchevsky+District,Moscow"
# Format: %c = weather icon, %t = temperature
FORMAT="%c+%t"

# Debug logging
echo "$(date): Script started" >> "$LOG_FILE"

# Set a timeout for curl to prevent hanging
# Fetch weather with icons
WEATHER=$(curl -s --max-time 10 "https://wttr.in/$LOCATION?format=$FORMAT")
EXIT_CODE=$?

# Simple validation: Check if output is not empty and reasonably short (avoid HTML errors)
LENGTH=${#WEATHER}

if [ $EXIT_CODE -eq 0 ] && [ -n "$WEATHER" ] && [ $LENGTH -lt 50 ]; then
    # Success: Save to cache and output
    # Remove leading/trailing whitespace (xargs trims by default)
    WEATHER=$(echo "$WEATHER" | xargs)
    echo "$WEATHER" > "$CACHE_FILE"
    echo "$(date): Success, weather is $WEATHER" >> "$LOG_FILE"
    echo "$WEATHER"
else
    # Failed: Try to read from cache
    echo "$(date): Failed. Exit code: $EXIT_CODE. Weather: $WEATHER" >> "$LOG_FILE"
    
    if [ -f "$CACHE_FILE" ] && [ -s "$CACHE_FILE" ]; then
        CACHED=$(cat "$CACHE_FILE")
        echo "$(date): Using cache: $CACHED" >> "$LOG_FILE"
        echo "$CACHED"
    else
        echo "N/A"
    fi
fi