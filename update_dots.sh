#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

REPO_DIR="$HOME/dotfiles"
WALLPAPER_SOURCE="$HOME/Pictures/wallpaper.png"

# List of all tools
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch" "gtk-3.0" "gtk-4.0")

GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting Backup...${NC}"

# 1. Setup Dirs
mkdir -p "$REPO_DIR/.config"
mkdir -p "$REPO_DIR/wallpapers"
mkdir -p "$REPO_DIR/.themes"

# 2. Copy Configs
for tool in "${CONFIGS[@]}"; do
    SRC="$HOME/.config/$tool"
    DEST="$REPO_DIR/.config/$tool"
    if [ -d "$SRC" ]; then
        rm -rf "$DEST"
        cp -r "$SRC" "$DEST"
        echo "Copied $tool"
    fi
done

# 3. Copy Themes & Wallpaper
if [ -d "$HOME/.themes" ]; then
    rm -rf "$REPO_DIR/.themes"
    cp -r "$HOME/.themes" "$REPO_DIR/"
fi
cp "$WALLPAPER_SOURCE" "$REPO_DIR/wallpapers/wallpaper.png"

# ==============================================================================
# GENERATE SMARTER INSTALLER
# ==============================================================================

cat > "$REPO_DIR/install.sh" << 'EOF'
#!/bin/bash
DOTFILES_DIR="$HOME/dotfiles"
TARGET_WALLPAPER="$HOME/Pictures/wallpaper.png"
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch" "gtk-3.0" "gtk-4.0")

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Installing Dotfiles...${NC}"

# 1. Symlink Configs
mkdir -p "$HOME/.config"
for tool in "${CONFIGS[@]}"; do
    SOURCE="$DOTFILES_DIR/.config/$tool"
    TARGET="$HOME/.config/$tool"
    
    # Remove existing folder/link and link the new one
    rm -rf "$TARGET"
    ln -sf "$SOURCE" "$TARGET"
done

# 2. Install Custom Themes
mkdir -p "$HOME/.themes"
if [ -d "$DOTFILES_DIR/.themes" ]; then
    cp -r "$DOTFILES_DIR/.themes/"* "$HOME/.themes/" 2>/dev/null
fi

# 3. Install Wallpaper
mkdir -p "$HOME/Pictures"
cp "$DOTFILES_DIR/wallpapers/wallpaper.png" "$TARGET_WALLPAPER"

# 4. FIX PATHS
USER_HOME=$(echo $HOME | sed 's/\//\\\//g')
HYPRLOCK="$HOME/.config/hypr/hyprlock.conf"
HYPRLAND="$HOME/.config/hypr/hyprland.conf"

if [ -f "$HYPRLOCK" ]; then
    sed -i "s/path = .*/path = $USER_HOME\/Pictures\/wallpaper.png/g" "$HYPRLOCK"
fi

if [ -f "$HYPRLAND" ]; then
    sed -i "s|swaybg -i .* -m|swaybg -i $HOME/Pictures/wallpaper.png -m|g" "$HYPRLAND"
fi

# 5. RESTART SERVICES (Crucial for Dunst)
echo "Restarting services..."

# Kill Dunst (it will auto-restart when a notification comes in)
killall dunst 2>/dev/null
# Reload Waybar
killall waybar; waybar & disown

# Send a test notification to force Dunst to start with new config
notify-send "Style Applied" "Your dotfiles have been installed successfully."

echo -e "${GREEN}Done!${NC}"
EOF

chmod +x "$REPO_DIR/install.sh"

# ==============================================================================
# GIT PUSH
# ==============================================================================

cd "$REPO_DIR" || exit
git add .
git commit -m "Update: Fixed Dunst reloading"
git push -u origin main
