#!/bin/bash
# --- DOTFILES INSTALLER ---

DOTFILES_DIR="$HOME/dotfiles"
TARGET_WALLPAPER="$HOME/Pictures/wallpaper.png"
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch")

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Installing Dotfiles...${NC}"

# 1. Symlink Configs
mkdir -p "$HOME/.config"
for tool in "${CONFIGS[@]}"; do
    SOURCE="$DOTFILES_DIR/.config/$tool"
    TARGET="$HOME/.config/$tool"

    if [ -d "$SOURCE" ]; then
        if [ -d "$TARGET" ] && [ ! -L "$TARGET" ]; then
            echo "Backing up existing $tool config..."
            mv "$TARGET" "${TARGET}.bak"
        fi
        
        echo "Linking $tool..."
        rm -rf "$TARGET"
        ln -sf "$SOURCE" "$TARGET"
    fi
done

# 2. Install Wallpaper
echo "Setting up wallpaper..."
mkdir -p "$HOME/Pictures"
cp "$DOTFILES_DIR/wallpapers/wallpaper.png" "$TARGET_WALLPAPER"

# 3. Fix Hyprlock Path
# This forces hyprlock to look at the user's specific home directory
HYPRLOCK_CONF="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$HYPRLOCK_CONF" ]; then
    echo "Updating lockscreen wallpaper path..."
    # Replaces any "path =" line with the correct local path
    sed -i "s|path = .*|path = $TARGET_WALLPAPER|g" "$HYPRLOCK_CONF"
fi

echo -e "${GREEN}Done! Restart Hyprland to see changes.${NC}"
