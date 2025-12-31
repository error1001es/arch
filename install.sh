#!/bin/bash

# 1. Установка yay (AUR помощник)
if ! command -v yay &> /dev/null; then
    echo "Устанавливаю yay..."
    git clone https://aur.archlinux.org/yay.git
    cd yay && makepkg -si --noconfirm
    cd .. && rm -rf yay
fi

# 2. Установка пакетов из файла packages.txt
echo "Устанавливаю пакеты..."
yay -S --noconfirm - < packages.txt

# 3. Установка Google Chrome (из AUR отдельно)
yay -S --noconfirm google-chrome xdg-desktop-portal-hyprland-git

# 4. Копирование конфигов (САМАЯ ВАЖНАЯ ЧАСТЬ)
echo "Копирую настройки..."
mkdir -p ~/.config
cp -r .config/* ~/.config/

# 5. Применение фиксов
echo "--ozone-platform-hint=auto" > ~/.config/chrome-flags.conf
sudo systemctl enable sddm

echo "Установка завершена! Перезагрузись."
