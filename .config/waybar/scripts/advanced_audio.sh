#!/bin/bash

# Config
THEME="$HOME/.config/rofi/sound.rasi"
ROFI_CMD="rofi -dmenu -theme $THEME"

# Functions to get info
get_default_sink() {
    pactl get-default-sink
}

get_default_source() {
    pactl get-default-source
}

get_sink_vol() {
    pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}' | tr -d '%'
}

get_source_vol() {
    pactl get-source-volume @DEFAULT_SOURCE@ | head -n 1 | awk '{print $5}' | tr -d '%'
}

get_sink_name() {
    pactl list sinks | grep -C2 "$(get_default_sink)" | grep "Description" | cut -d: -f2 | xargs
}

get_source_name() {
    pactl list sources | grep -C2 "$(get_default_source)" | grep "Description" | cut -d: -f2 | xargs
}

# --- Main Menu Generator ---
main_menu() {
    sink_name=$(get_sink_name)
    source_name=$(get_source_name)
    sink_vol=$(get_sink_vol)
    source_vol=$(get_source_vol)

    echo -e "🔊 Output: $sink_name\n🎤 Input: $source_name\n🔈 Output Volume: ${sink_vol}%\n🎙  Input Volume: ${source_vol}%"
}

# --- Sub Menus ---
select_sink() {
    # Parse sinks: ID 	 Description
    pactl list sinks | grep -E 'Name:|Description:' | awk 'NR%2{printf "%s\t", $2} NR%2==0{ $1=""; print $0}' | sed 's/Name: //; s/Description: //' | \
    while IFS=$'\t' read -r name desc; do
        if [ "$name" == "$(get_default_sink)" ]; then
            echo -e "* $desc\0icon\x1faudio-card\x1finfo\x1f$name"
        else
            echo -e "  $desc\0icon\x1faudio-card\x1finfo\x1f$name"
        fi
    done
}

select_source() {
    pactl list sources | grep -v ".monitor" | grep -E 'Name:|Description:' | awk 'NR%2{printf "%s\t", $2} NR%2==0{ $1=""; print $0}' | sed 's/Name: //; s/Description: //' | \
    while IFS=$'\t' read -r name desc; do
        if [ "$name" == "$(get_default_source)" ]; then
            echo -e "* $desc\0icon\x1fmicrophone\x1finfo\x1f$name"
        else
            echo -e "  $desc\0icon\x1fmicrophone\x1finfo\x1f$name"
        fi
    done
}

gen_vol_list() {
    # Generate volume steps
    current=$1
    echo -e "🔇 Mute\0info\x1fmute"
    for i in {0..120..10}; do
        bar=""
        # Simple progress bar
        dots=$((i / 10))
        for ((j=0; j<dots; j++)); do bar="${bar}█"; done
        for ((j=dots; j<12; j++)); do bar="${bar}░"; done
        
        if [ "$i" -eq "$current" ]; then
            echo -e "* $i%  $bar\0info\x1f$i"
        else
            echo -e "  $i%  $bar\0info\x1f$i"
        fi
    done
}

# --- Logic ---

# Check if arguments passed to handle sub-menus
case "$1" in
    "select_sink")
        selection=$(select_sink | $ROFI_CMD -p "Select Output" -format 'i s')
        if [ -n "$selection" ]; then
            # Extract name from the info field (requires rofi support or parsing line)
            # Simplified: re-parse list based on index or parsing text
            # Better approach: We use the text directly if simple, but here we used info hack.
            # Let's simple parse the 'Name' from the line if possible, or use the pactl list again.
            # Rofi dmenu returns the string. Let's rely on grep.
            
            # Let's keep it simple: Just rerun logic inside the script
            # We will use specific format for selection to make it easier
             sink_id=$(echo "$selection" | awk -F'\x1f' '{print $3}')
             # Fallback if binary data not preserved (dmenu mode usually strips hidden info without specific flags)
             # Actually, simpler way for bash script without complex rofi flags:
             
             # Re-implementation for robust selection:
             # Just list descriptions.
             :
        fi
        ;; 
esac

# Interactive Loop
while true; do
    # Show Main Menu
    selection=$(main_menu | $ROFI_CMD -p "Audio Control")

    if [ -z "$selection" ]; then
        exit 0
    fi

    case "$selection" in
        *"Output:"*) 
            # Get list of sinks
            # Format: "Description [Name]"
            options=$(pactl list sinks | grep 'Description:' | cut -d: -f2 | sed 's/^	*//')
            # Add Names hidden? No, let's map them.
            # Simplest way: List descriptions, find index, get name by index.
            
            chosen_desc=$(echo "$options" | $ROFI_CMD -p "Select Output")
            if [ -n "$chosen_desc" ]; then
                # Find the name associated with this description
                # Warning: This fails if multiple devices have same description.
                sink_name=$(pactl list sinks | grep -B1 "Description: $chosen_desc" | grep "Name:" | head -n1 | cut -d: -f2 | xargs)
                pactl set-default-sink "$sink_name"
                # Move inputs
                pactl list short sink-inputs | cut -f1 | while read -r input; do
                    pactl move-sink-input "$input" "$sink_name"
                done
            fi
            ;; 
            
        *"Input:"*) 
            options=$(pactl list sources | grep -v ".monitor" | grep 'Description:' | cut -d: -f2 | sed 's/^	*//')
            chosen_desc=$(echo "$options" | $ROFI_CMD -p "Select Input")
            if [ -n "$chosen_desc" ]; then
                source_name=$(pactl list sources | grep -B1 "Description: $chosen_desc" | grep "Name:" | head -n1 | cut -d: -f2 | xargs)
                pactl set-default-source "$source_name"
            fi
            ;; 
            
        *"Output Volume"*) 
            cur=$(get_sink_vol)
            chosen=$(gen_vol_list $cur | $ROFI_CMD -p "Output Volume")
            if [[ "$chosen" == *"Mute"* ]]; then
                pactl set-sink-mute @DEFAULT_SINK@ toggle
            elif [ -n "$chosen" ]; then
                vol=$(echo "$chosen" | awk '{print $1}' | tr -d '%*')
                pactl set-sink-volume @DEFAULT_SINK@ "${vol}%"
                pactl set-sink-mute @DEFAULT_SINK@ 0
            fi
            ;; 
            
        *"Input Volume"*) 
            cur=$(get_source_vol)
            chosen=$(gen_vol_list $cur | $ROFI_CMD -p "Input Volume")
            if [[ "$chosen" == *"Mute"* ]]; then
                pactl set-source-mute @DEFAULT_SOURCE@ toggle
            elif [ -n "$chosen" ]; then
                vol=$(echo "$chosen" | awk '{print $1}' | tr -d '%*')
                pactl set-source-volume @DEFAULT_SOURCE@ "${vol}%"
                pactl set-source-mute @DEFAULT_SOURCE@ 0
            fi
            ;; 
    esac
done
