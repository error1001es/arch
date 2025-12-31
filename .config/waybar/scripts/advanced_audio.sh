#!/bin/bash

# Config
THEME="$HOME/.config/rofi/sound.rasi"
# Using -format 'i s' to get both index and string if needed, but simple string matching is easier for now.
# We remove the custom separator logic that caused "strange symbols".
ROFI_CMD="rofi -dmenu -theme $THEME -p"

# --- Helpers ---

get_default_sink() {
    pactl get-default-sink
}

get_default_source() {
    pactl get-default-source
}

get_volume() {
    # $1 = @DEFAULT_SINK@ or @DEFAULT_SOURCE@
    pactl get-sink-volume "$1" 2>/dev/null | head -n 1 | awk '{print $5}' | tr -d '%' || \
    pactl get-source-volume "$1" 2>/dev/null | head -n 1 | awk '{print $5}' | tr -d '%' 
}

# --- Parsing Sinks/Sources ---
# We use arrays to strictly map Descriptions to Names

# Read Sink Names (Technical IDs)
mapfile -t SINK_NAMES < <(pactl list short sinks | awk '{print $2}')
# Read Sink Descriptions (Pretty Names)
mapfile -t SINK_DESCS < <(pactl list sinks | grep 'Description:' | cut -d: -f2 | sed 's/^[ 	]*//')

# Read Source Names
mapfile -t SOURCE_NAMES < <(pactl list short sources | grep -v "\.monitor" | awk '{print $2}')
mapfile -t SOURCE_DESCS < <(pactl list sources | grep -v "\.monitor" | grep 'Description:' | cut -d: -f2 | sed 's/^[ 	]*//')


# --- Menus ---

main_menu() {
    # Get current state
    cur_sink=$(get_default_sink)
    cur_source=$(get_default_source)
    
    # Find pretty name for current sink
    cur_sink_desc="Unknown"
    for i in "${!SINK_NAMES[@]}"; do
        if [[ "${SINK_NAMES[$i]}" == "$cur_sink" ]]; then
            cur_sink_desc="${SINK_DESCS[$i]}"
            break
        fi
    done

    # Find pretty name for current source
    cur_source_desc="Unknown"
    for i in "${!SOURCE_NAMES[@]}"; do
        if [[ "${SOURCE_NAMES[$i]}" == "$cur_source" ]]; then
            cur_source_desc="${SOURCE_DESCS[$i]}"
            break
        fi
    done
    
    vol_out=$(get_volume @DEFAULT_SINK@)
    vol_in=$(get_volume @DEFAULT_SOURCE@)

    # Output lines
    echo "🔊 Out: $cur_sink_desc"
    echo "🎤 In:  $cur_source_desc"
    echo "🔈 Vol Out: $vol_out%"
    echo "🎙  Vol In:  $vol_in%"
}

# --- Actions ---

# Infinite loop to keep menu open until explicit exit
while true; do
    selection=$(main_menu | $ROFI_CMD "Audio")

    if [ -z "$selection" ]; then
        exit 0
    fi

    case "$selection" in
        "🔊 Out"*) 
            # Generate list for rofi
            list=""
            for desc in "${SINK_DESCS[@]}"; do
                list+="$desc\n"
            done
            chosen_desc=$(echo -e "$list" | $ROFI_CMD "Select Output")
            
            # Find corresponding Name
            if [ -n "$chosen_desc" ]; then
                for i in "${!SINK_DESCS[@]}"; do
                    if [[ "${SINK_DESCS[$i]}" == "$chosen_desc" ]]; then
                        target="${SINK_NAMES[$i]}"
                        pactl set-default-sink "$target"
                        # Move inputs
                        pactl list short sink-inputs | cut -f1 | while read -r input; do
                            pactl move-sink-input "$input" "$target"
                        done
                        break
                    fi
                done
            fi
            ;; 
            
        "🎤 In"*) 
            list=""
            for desc in "${SOURCE_DESCS[@]}"; do
                list+="$desc\n"
            done
            chosen_desc=$(echo -e "$list" | $ROFI_CMD "Select Input")
            
            if [ -n "$chosen_desc" ]; then
                for i in "${!SOURCE_DESCS[@]}"; do
                    if [[ "${SOURCE_DESCS[$i]}" == "$chosen_desc" ]]; then
                        target="${SOURCE_NAMES[$i]}"
                        pactl set-default-source "$target"
                        break
                    fi
                done
            fi
            ;; 
            
        "🔈 Vol Out"*) 
            # Simulate a slider with a list
            # Rofi doesn't support real sliders, so we offer presets
            options="Start pavucontrol (Advanced)\nMute\n120%\n100%\n90%\n80%\n70%\n60%\n50%\n40%\n30%\n20%\n10%\n0%"
            choice=$(echo -e "$options" | $ROFI_CMD "Volume Out")
            
            if [[ "$choice" == *"pavucontrol"* ]]; then
                pavucontrol &
                exit 0
            elif [[ "$choice" == "Mute" ]]; then
                pactl set-sink-mute @DEFAULT_SINK@ toggle
            elif [[ "$choice" == *"%" ]]; then
                val=${choice%
}
                pactl set-sink-volume @DEFAULT_SINK@ "${val}%"
                pactl set-sink-mute @DEFAULT_SINK@ 0
            fi
            ;;

        "🎙  Vol In"*) 
            options="Mute\n100%\n80%\n60%\n40%\n20%\n0%"
            choice=$(echo -e "$options" | $ROFI_CMD "Volume In")
            
             if [[ "$choice" == "Mute" ]]; then
                pactl set-source-mute @DEFAULT_SOURCE@ toggle
            elif [[ "$choice" == *"%" ]]; then
                val=${choice%
}
                pactl set-source-volume @DEFAULT_SOURCE@ "${val}%"
                pactl set-source-mute @DEFAULT_SOURCE@ 0
            fi
            ;; 
    esac
done