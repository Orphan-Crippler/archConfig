#!/bin/bash
current_user=$(whoami)

# Define color codes as variables
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color/Reset

# 1. Set up logging
# Create a log file with the current date and time
LOG_FILE="log$(date +%H%M%S)"

# Redirect stdout (1) and stderr (2) to 'tee', which prints to the screen AND writes to the file
exec > >(tee -i "$LOG_FILE") 2>&1

# Exit immediately if any command fails
set -e

# Ensure the script is NOT run as root
if [ "$EUID" -eq 0 ]; then
  echo "${RED}*****************************************${NC}"
  echo "Error: Please run this script as your normal user, not as root."
  exit 1
fi

echo "${GREEN}=========================================${NC}"
echo " Package install & config setup engaged."
echo "${GREEN}=========================================${NC}"
echo "Log file: $LOG_FILE"
echo "${GREEN}=========================================${NC}"

# 2. Enable temporary passwordless sudo
echo "Automation authentication requested..."
echo "${GREEN}*****************************************${NC}"
# This is the ONLY time you will be prompted for a password
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/temp_nopasswd > /dev/null

# Set the fail-safe trap to ALWAYS revoke passwordless sudo when the script exits
trap 'echo "Automation rights revoked..."; sudo rm -f /etc/sudoers.d/temp_nopasswd; echo "Installation finished. Check $LOG_FILE for details."' EXIT

# 3. Update system and install base development tools
curl -O -L https://raw.githubusercontent.com/Orphan-Crippler/archConfig/refs/heads/master/pkglist.txt
curl -O -L https://raw.githubusercontent.com/Orphan-Crippler/archConfig/refs/heads/master/aurlist.txt
echo "${GREEN}=========================================${NC}"
echo "Updating system and installing base-devel..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel

# 4. Install official packages
if [ -f "pkglist.txt" ]; then
    echo "${GREEN}=========================================${NC}"
    echo "Pacman Go!!!"
    sudo pacman -S --needed --noconfirm - < pkglist.txt
else
    echo "${RED}*****************************************${NC}"
    echo "Warning: pkglist.txt not found. Pacman was killed by a ghost..."
fi

# 5. Install yay
if ! command -v yay &> /dev/null; then
    echo "${GREEN}=========================================${NC}"
    echo "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    
    # Run the build in a subshell () so it doesn't change the script's working directory
    (
        cd /tmp/yay-build
        makepkg -si --noconfirm
    )
    
    rm -rf /tmp/yay-build
else
    echo "${RED}*****************************************${NC}"
    echo "yay is already installed."
fi

# 6. Install AUR packages
if [ -f "aurlist.txt" ]; then
    echo "${GREEN}=========================================${NC}"
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm - < aurlist.txt
else
    echo "${RED}*****************************************${NC}"
    echo "Warning: aurlist.txt not found. Skipping AUR packages."
fi

# 7. Install Oh My Zsh automatically
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "${GREEN}=========================================${NC}"
    echo "Installing Oh,My,ZSH..."
    # RUNZSH=no: Prevents dropping into a zsh prompt
    # UNATTENDED=yes: Skips the "do you want to change your default shell" prompt
    # KEEP_ZSHRC=yes: Protects your existing .zshrc if you already pulled it
    RUNZSH=no UNATTENDED=yes KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    # Manually change the default shell to Zsh for your user
    echo "${GREEN}=========================================${NC}"
    echo "Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)"
else
    echo "${GREEN}=========================================${NC}"
    echo "Oh My Zsh is already installed. Skipping."
fi

# 11. Install Powerlevel10k
echo "${GREEN}=========================================${NC}"
echo "Powerleveling up to 10K!!!!!!!!!!!!!!!!!!"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

# 7. Pull .config from GitHub and put shit where it belongs
# Replace the URL below with your actual repository link
GITHUB_REPO="https://github.com/Orphan-Crippler/archConfig.git"

echo "${GREEN}=========================================${NC}"
echo "Loading configuration files..."
git clone "$GITHUB_REPO" /tmp/dotfiles-config
mkdir -p "$HOME/.config"
cp -a /tmp/dotfiles-config/. "$HOME/.config/"
rm -rf /tmp/dotfiles-config
sudo mv "$HOME/.config/cloud/sddm.conf" /etc/
mkdir -p /usr/share/sddm/themes
sudo mv "$HOME/.config/cloud" /usr/share/sddm/themes/
sudo mv "$HOME/.config/.zshrc" "$HOME/"

echo "${GREEN}=========================================${NC}"
echo "       Setup & config complete!!!"
echo "${GREEN}=========================================${NC}"
echo "    zsh & p10k need to be configured"
echo "${GREEN}=========================================${NC}"
echo " Run hyprwhspr setup then reboot machine."
echo "${GREEN}=========================================${NC}"

# The trap will automatically run here to clean up sudo access.
