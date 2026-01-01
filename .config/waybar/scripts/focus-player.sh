#!/bin/bash

# Получаем PID процесса, который воспроизводит медиа
# Перенаправляем stderr в /dev/null, чтобы скрыть ошибку "No player could handle this command", если ничего не играет
PID=$(playerctl metadata mpris:processId 2>/dev/null)

if [ -n "$PID" ]; then
    # Говорим Hyprland сфокусировать окно с этим PID
    # Это также переключит воркспейс, если окно на другом
    hyprctl dispatch focuswindow pid:$PID
fi