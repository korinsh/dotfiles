#!/bin/bash

# Define where the dotfiles are (Dynamic Path)
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch" "gtk-3.0" "gtk-4.0")

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "=== STARTING INSTALLATION ==="
echo "Source: $DOTFILES_DIR"

mkdir -p "$HOME/.config"

# 1. LINKING CONFIGS
for tool in "${CONFIGS[@]}"; do
    SOURCE="$DOTFILES_DIR/.config/$tool"
    TARGET="$HOME/.config/$tool"

    # Check if Source exists in the repo
    if [ ! -d "$SOURCE" ]; then
        echo -e "${RED}[FAIL] $tool not found in dotfiles folder!${NC}"
        continue
    fi

    # AGGRESSIVE LINKING
    # 1. Remove whatever is currently at the target (Folder or Link)
    rm -rf "$TARGET"
    
    # 2. Create the symlink
    ln -s "$SOURCE" "$TARGET"

    # 3. Verify
    if [ -L "$TARGET" ]; then
        echo -e "${GREEN}[OK] Linked $tool${NC}"
    else
        echo -e "${RED}[FAIL] Could not link $tool${NC}"
    fi
done

# 2. THEMES & WALLPAPER
echo "--- Installing Extras ---"
mkdir -p "$HOME/.themes" "$HOME/Pictures"

# Copy Themes
if [ -d "$DOTFILES_DIR/.themes" ]; then
    cp -r "$DOTFILES_DIR/.themes/"* "$HOME/.themes/" 2>/dev/null
    echo "[OK] Themes Installed"
fi

# Copy Wallpaper
if [ -f "$DOTFILES_DIR/wallpapers/wallpaper.png" ]; then
    cp "$DOTFILES_DIR/wallpapers/wallpaper.png" "$HOME/Pictures/wallpaper.png"
    echo "[OK] Wallpaper Installed"
fi

# 3. FIX HYPRLAND/HYPRLOCK PATHS
echo "--- Fixing Paths ---"
HYPRLAND="$HOME/.config/hypr/hyprland.conf"
HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"
IMG_PATH="$HOME/Pictures/wallpaper.png"

# We use perl for regex because sed can be annoying with paths
if [ -f "$HYPRLAND" ]; then
    sed -i "s|swaybg -i .* -m|swaybg -i $IMG_PATH -m|g" "$HYPRLAND"
    echo "[OK] Hyprland Config Updated"
fi
if [ -f "$HYPRLOCK" ]; then
    sed -i "s|path = .*|path = $IMG_PATH|g" "$HYPRLOCK"
    echo "[OK] Hyprlock Config Updated"
fi

# 4. RESTART SERVICES
echo "--- Restarting Services ---"
killall dunst 2>/dev/null
killall waybar 2>/dev/null

# Start Waybar background
waybar & disown

# Send test notification
notify-send "INSTALL COMPLETE" "Your dotfiles are active."

echo -e "${GREEN}=== DONE ===${NC}"
