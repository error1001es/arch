#!/bin/bash

# Получаем данные о выходе (Sink)
SINK_DESC=$(pactl list sinks | grep -C2 "$(pactl get-default-sink)" | grep "Description" | cut -d: -f2 | xargs)
SINK_VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | head -n 1 | awk '{print $5}')
SINK_MUTE=$(pactl get-sink-mute @DEFAULT_SINK@ | awk '{print $2}')

# Получаем данные о входе (Source)
SOURCE_DESC=$(pactl list sources | grep -v ".monitor" | grep -C2 "$(pactl get-default-source)" | grep "Description" | cut -d: -f2 | xargs)
SOURCE_VOL=$(pactl get-source-volume @DEFAULT_SOURCE@ | head -n 1 | awk '{print $5}')
SOURCE_MUTE=$(pactl get-source-mute @DEFAULT_SOURCE@ | awk '{print $2}')

# Иконка для панели
if [ "$SINK_MUTE" == "yes" ]; then
    ICON="󰝟"
else
    ICON="󰕾"
fi

# Текст в самой панели
TEXT="$ICON $SINK_VOL"

# Текст в подсказке (Tooltip)
# Мы используем \n для переноса строки
TOOLTIP="1. Вывод: $SINK_DESC ($SINK_VOL)\n2. Ввод: $SOURCE_DESC ($SOURCE_VOL)"

# Вывод в формате JSON
printf '{"text": "%s", "tooltip": "%s"}\n' "$TEXT" "$TOOLTIP"
