#!/bin/bash

# Debugging
LOG_FILE="/tmp/sound_menu.log"
echo "Script started at $(date)" > "$LOG_FILE"

# Configuration
ROFI_CMD="rofi -dmenu -i -p"

# Get current volumes
sink_vol=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}')
source_vol=$(pactl get-source-volume @DEFAULT_SOURCE@ | head -n 1 | awk '{print $5}')

echo "Volumes: Sink=$sink_vol, Source=$source_vol" >> "$LOG_FILE"

# Main options
options="🔊 Output Device\n🎤 Input Device\n🔊 Output Volume [$sink_vol]\n🎤 Input Volume [$source_vol]"

selected=$(echo -e "$options" | $ROFI_CMD "Audio Control")

echo "Selected: $selected" >> "$LOG_FILE"

case "$selected" in
    "🔊 Output Device")
        # Get list of sinks with descriptions (requires more complex parsing or assume names are okay)
        # Using list short for simplicity, but extracting names
        # pactl -f json list sinks is better if available, but let's stick to basic text parsing for compatibility
        # We will list ID and Name
        sinks=$(pactl list short sinks | awk '{print $1 ": " $2}')
        chosen_sink=$(echo -e "$sinks" | $ROFI_CMD "Select Output")
        if [ -n "$chosen_sink" ]; then
            sink_id=$(echo "$chosen_sink" | cut -d':' -f1)
            pactl set-default-sink "$sink_id"
            # Move all currently playing streams to the new sink
            pactl list short sink-inputs | cut -f1 | while read -r input; do
                pactl move-sink-input "$input" "$sink_id"
            done
        fi
        ;;
    "🎤 Input Device")
        sources=$(pactl list short sources | grep -v "\.monitor" | awk '{print $1 ": " $2}')
        chosen_source=$(echo -e "$sources" | $ROFI_CMD "Select Input")
        if [ -n "$chosen_source" ]; then
            source_id=$(echo "$chosen_source" | cut -d':' -f1)
            pactl set-default-source "$source_id"
        fi
        ;;
    *"Output Volume"*) # Corrected from *