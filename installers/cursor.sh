cd /tmp && wget https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz
tar -xvf Bibata-Modern-Ice.tar.xz
mkdir -p ~/.local/share/icons
mv Bibata-Modern-Ice ~/.local/share/icons/
hyprpm update
hyprpm add https://github.com/virtcode/hypr-dynamic-cursors
hyprpm enable dynamic-cursors
