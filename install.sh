#!/bin/bash
# --- ROBUST DOTFILES INSTALLER ---

# 1. Detect where this script is running from
# This fixes the issue of hardcoded paths
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TARGET_WALLPAPER="$HOME/Pictures/wallpaper.png"
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch" "gtk-3.0" "gtk-4.0")

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Applying Dotfiles from: $SCRIPT_DIR${NC}"

# 2. Link Configs Safely
mkdir -p "$HOME/.config"

for tool in "${CONFIGS[@]}"; do
    SOURCE="$SCRIPT_DIR/.config/$tool"
    TARGET="$HOME/.config/$tool"

    # Only proceed if the config actually exists in the repo
    if [ -d "$SOURCE" ]; then
        # Check if target exists
        if [ -d "$TARGET" ] || [ -L "$TARGET" ]; then
            # If it's already a correct link, skip
            CURRENT_LINK=$(readlink -f "$TARGET")
            if [ "$CURRENT_LINK" == "$SOURCE" ]; then
                echo "Skipping $tool (Already linked)"
                continue
            fi
            
            # Backup existing config just in case
            mv "$TARGET" "${TARGET}.backup-$(date +%s)"
            echo "Backed up old $tool config"
        fi

        # Create the Symlink
        ln -sfn "$SOURCE" "$TARGET"
        echo -e "Linked: ${GREEN}$tool${NC}"
    else
        echo -e "${RED}Error: Config for $tool not found in repo!${NC}"
    fi
done

# 3. Install Themes
if [ -d "$SCRIPT_DIR/.themes" ]; then
    mkdir -p "$HOME/.themes"
    cp -r "$SCRIPT_DIR/.themes/"* "$HOME/.themes/" 2>/dev/null
    echo "Installed Themes"
fi

# 4. Install Wallpaper
mkdir -p "$HOME/Pictures"
if [ -f "$SCRIPT_DIR/wallpapers/wallpaper.png" ]; then
    cp "$SCRIPT_DIR/wallpapers/wallpaper.png" "$TARGET_WALLPAPER"
    echo "Installed Wallpaper"
fi

# 5. Fix Paths (Swaybg & Hyprlock)
USER_HOME_ESCAPED=$(echo $HOME | sed 's/\//\\\//g')
HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"
HYPRLAND="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPRLOCK" ]; then
    sed -i "s/path = .*/path = $USER_HOME_ESCAPED\/Pictures\/wallpaper.png/g" "$HYPRLOCK"
fi

if [ -f "$HYPRLAND" ]; then
    sed -i "s|swaybg -i .* -m|swaybg -i $HOME/Pictures/wallpaper.png -m|g" "$HYPRLAND"
fi

# 6. Force Reload Services
echo "Reloading services..."
killall dunst 2>/dev/null
killall waybar 2>/dev/null

# Start waybar in background
waybar & disown

# Send test notification (Restarts Dunst)
notify-send "Config Applied" "Your system has been updated."

echo -e "${GREEN}Installation Complete!${NC}"
