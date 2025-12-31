#!/bin/bash

# 0. Подготовка pacman и установка базовых зависимостей
echo "Обновляю базы и устанавливаю git/base-devel..."
sudo pacman -Sy --noconfirm git base-devel

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

# 3. Установка других AUR пакетов
yay -S --noconfirm xdg-desktop-portal-hyprland-git

# 4. Копирование конфигов (САМАЯ ВАЖНАЯ ЧАСТЬ)
echo "Копирую настройки..."
mkdir -p ~/.config
cp -r .config/* ~/.config/

# Копирование обоев
echo "Копирую обои..."
mkdir -p ~/Pictures
if [ -f "wallpaper.jpg" ]; then
    cp wallpaper.jpg ~/Pictures/
else
    # Если файла нет в репо, генерируем его (fallback)
    ffmpeg -f lavfi -i color=c=black:s=2560x1440 -frames:v 1 ~/Pictures/wallpaper.jpg
fi

# 5. Применение фиксов
echo "Включаю SDDM..."
sudo systemctl enable sddm

echo "Установка завершена! Перезагрузись."
