#!/bin/bash
# Запускаем Kitty с уникальным классом, прозрачностью и удерживаем окно открытым
kitty --class="dashboard" --title="Dashboard" --hold sh -c "fastfetch"
kitty --hold sh -c "v2rayN"
