#!/bin/bash

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# The folder that will be sent to GitHub
REPO_DIR="$HOME/dotfiles"

# EXACT location of your current wallpaper
WALLPAPER_SOURCE="$HOME/Pictures/wallpaper.png"

# List of configs to backup from ~/.config/
CONFIGS=("kitty" "waybar" "dunst" "hypr" "wofi" "fastfetch")

# Your GitHub URL (Optional: Set this if you haven't set it manually yet)
# GITHUB_URL="https://github.com/korinsh/dotfiles"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# ==============================================================================
# BACKUP PROCESS (Your Machine -> Repo)
# ==============================================================================

echo -e "${BLUE}Starting Backup...${NC}"

# 1. Create Repo Directories
mkdir -p "$REPO_DIR/.config"
mkdir -p "$REPO_DIR/wallpapers"

# 2. Copy Config Folders
for tool in "${CONFIGS[@]}"; do
    SRC="$HOME/.config/$tool"
    DEST="$REPO_DIR/.config/$tool"

    if [ -d "$SRC" ]; then
        echo -e "Copying ${GREEN}$tool${NC}..."
        rm -rf "$DEST" # Remove old backup to sync deletions
        cp -r "$SRC" "$DEST"
    else
        echo -e "${RED}Warning:${NC} $SRC not found. Skipping."
    fi
done

# 3. Copy Wallpaper
if [ -f "$WALLPAPER_SOURCE" ]; then
    echo -e "Copying Wallpaper from ${GREEN}$WALLPAPER_SOURCE${NC}..."
    cp "$WALLPAPER_SOURCE" "$REPO_DIR/wallpapers/wallpaper.png"
else
    echo -e "${RED}ERROR:${NC} Wallpaper not found at $WALLPAPER_SOURCE"
    echo "Please rename your wallpaper to 'wallpaper.png' and put it in ~/Pictures/"
fi

# ==============================================================================
# GENERATE INSTALLER (The script for other users)
# ==============================================================================

echo -e "Generating ${GREEN}install.sh${NC}..."

cat > "$REPO_DIR/install.sh" << 'EOF'
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
EOF

chmod +x "$REPO_DIR/install.sh"

# ==============================================================================
# GIT PUSH
# ==============================================================================

cd "$REPO_DIR" || exit

# Init git if needed
if [ ! -d ".git" ]; then
    echo "Initializing Git..."
    git init
    git branch -M main
fi

# Add Remote if GITHUB_URL is set in this script and remote doesn't exist
if [ -n "$GITHUB_URL" ] && ! git remote | grep -q origin; then
    git remote add origin "$GITHUB_URL"
fi

echo -e "${BLUE}Pushing to GitHub...${NC}"
git add .
git commit -m "Update dotfiles $(date +'%Y-%m-%d %H:%M')"

# Try to push
if git push -u origin main; then
    echo -e "${GREEN}Success! Your GitHub repo is updated.${NC}"
else
    echo -e "${RED}Push failed.${NC}"
    echo "If this is your first time, run this command manually inside ~/dotfiles:"
    echo "git remote add origin https://github.com/YOUR_USERNAME/dotfiles.git"
    echo "git push -u origin main"
fi
