#!/bin/bash

# Получаем список sink'ов (выходов)
# Формат: ID Name Description
# Используем pactl -f json если версия свежая, но для надежности старый метод:

SINK_DATA=$(pactl list sinks | grep -E 'Sink #|Description:|Name:')

# Парсим и готовим список для Rofi
# Нам нужно показать Description, но знать Name/ID для переключения

# Извлекаем имена и описания в массивы
names=($(pactl list short sinks | awk '{print $2}'))
# Описания сложнее вытащить одной строкой awk из-за пробелов, используем цикл
descriptions=()
while IFS= read -r line; do
    descriptions+=("$line")
done < <(pactl list sinks | grep 'Description:' | cut -d: -f2 | sed 's/^[ \t]*//')

# Формируем список для Rofi
list_str=""
for i in "${!names[@]}"; do
    # Добавляем маркер если это текущий дефолтный sink
    current=$(pactl get-default-sink)
    if [ "${names[$i]}" == "$current" ]; then
        prefix="* "
    else
        prefix="  "
    fi
    list_str+="${prefix}${descriptions[$i]} [${names[$i]}]\n"
done

# Показываем Rofi
selected=$(echo -e "$list_str" | rofi -dmenu -i -p "Audio Output" -width 40 -lines 5)

if [ -n "$selected" ]; then
    # Извлекаем имя (то, что в квадратных скобках в конце)
    chosen_sink=$(echo "$selected" | sed 's/.*\[\(.*\)]$/\1/')
    
    if [ -n "$chosen_sink" ]; then
        pactl set-default-sink "$chosen_sink"
        
        # Перемещаем все текущие потоки на новый выход
        pactl list short sink-inputs | cut -f1 | while read -r input; do
            pactl move-sink-input "$input" "$chosen_sink"
        done
        
        notify-send "Audio Output Changed" "Switched to: $chosen_sink"
    fi
fi
