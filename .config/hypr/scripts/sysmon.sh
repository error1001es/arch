#!/bin/bash
# Запускаем Kitty с уникальным классом, прозрачностью и удерживаем окно открытым
kitty --class="sysmon" --title="System Monitor" --hold sh -c "btop"
