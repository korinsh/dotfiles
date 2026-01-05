#!/bin/bash

# ==============================================================================
# 1. SETUP & VARIABLES
# ==============================================================================

REPO_DIR="$HOME/dotfiles"
WALLPAPER_SOURCE="$HOME/Pictures/wallpaper.png"
# All the configs you want to manage
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch" "gtk-3.0" "gtk-4.0")

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Robust Backup ===${NC}"

# ==============================================================================
# 2. BACKUP LOCAL CONFIGS -> REPO
# ==============================================================================

# Prepare Repo Structure
mkdir -p "$REPO_DIR/.config"
mkdir -p "$REPO_DIR/wallpapers"
mkdir -p "$REPO_DIR/.themes"

# Copy Configs
for tool in "${CONFIGS[@]}"; do
    SRC="$HOME/.config/$tool"
    DEST="$REPO_DIR/.config/$tool"
    
    if [ -d "$SRC" ]; then
        # Clean destination to ensure exact sync
        rm -rf "$DEST"
        cp -r "$SRC" "$DEST"
        echo -e "Backed up: ${GREEN}$tool${NC}"
    else
        echo -e "${RED}Skipped (Not found): $tool${NC}"
    fi
done

# Copy Themes (if exists)
if [ -d "$HOME/.themes" ]; then
    rm -rf "$REPO_DIR/.themes"
    cp -r "$HOME/.themes" "$REPO_DIR/"
    echo "Backed up: Custom Themes"
fi

# Copy Wallpaper
if [ -f "$WALLPAPER_SOURCE" ]; then
    cp "$WALLPAPER_SOURCE" "$REPO_DIR/wallpapers/wallpaper.png"
    echo "Backed up: Wallpaper"
else
    echo -e "${RED}Warning: Wallpaper not found at $WALLPAPER_SOURCE${NC}"
fi

# ==============================================================================
# 3. GENERATE THE FIXED INSTALLER (install.sh)
# ==============================================================================

echo "Generating install.sh..."

cat > "$REPO_DIR/install.sh" << 'EOF'
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
EOF

chmod +x "$REPO_DIR/install.sh"

# ==============================================================================
# 4. GIT PUSH
# ==============================================================================

cd "$REPO_DIR" || exit

if [ ! -d ".git" ]; then
    git init
    git branch -M main
fi

git add .
git commit -m "Fix: Robust installer with dynamic paths"
git push -u origin main
