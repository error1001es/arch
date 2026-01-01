#!/bin/bash
# Запускаем Kitty с уникальным классом, прозрачностью и удерживаем окно открытым
kitty --class="dashboard" --title="Dashboard" -o background_opacity=0.6 --hold sh -c "fastfetch"
