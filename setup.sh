#!/bin/bash
current_user=$(whoami)

# 1. Set up logging
# Create a log file with the current date and time
LOG_FILE="log_$(date %H%M%S)"

# Redirect stdout (1) and stderr (2) to 'tee', which prints to the screen AND writes to the file
exec > >(tee -i "$LOG_FILE") 2>&1

# Exit immediately if any command fails
set -e

# Ensure the script is NOT run as root
if [ "$EUID" -eq 0 ]; then
  echo "*****************************************"
  echo "Error: Please run this script as your normal user, not as root."
  exit 1
fi

echo "========================================="
echo " Package install & config setup engaged."
echo "========================================="
echo "Log file: $LOG_FILE"
echo "========================================="

# 2. Enable temporary passwordless sudo
echo "Automation authentication requested..."
echo "*****************************************"
# This is the ONLY time you will be prompted for a password
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/temp_nopasswd > /dev/null

# Set the fail-safe trap to ALWAYS revoke passwordless sudo when the script exits
trap 'echo "Automation rights revoked..."; sudo rm -f /etc/sudoers.d/temp_nopasswd; echo "Installation finished. Check $LOG_FILE for details."' EXIT

# 3. Update system and install base development tools
echo "========================================="
echo "Updating system and installing base-devel..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm base-devel

# 4. Install official packages
if [ -f "pkglist.txt" ]; then
    echo "========================================="
    echo "Pacman Go!!!"
    sudo pacman -S --needed --noconfirm - < pkglist.txt
else
    echo "*****************************************"
    echo "Warning: pkglist.txt not found. Pacman was killed by a ghost..."
fi

# 5. Install yay
if ! command -v yay &> /dev/null; then
    echo "========================================="
    echo "Installing yay (AUR helper)..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    
    # Run the build in a subshell () so it doesn't change the script's working directory
    (
        cd /tmp/yay-build
        makepkg -si --noconfirm
    )
    
    rm -rf /tmp/yay-build
else
    echo "*****************************************"
    echo "yay is already installed."
fi

# 6. Install AUR packages
if [ -f "aurlist.txt" ]; then
    echo "========================================="
    echo "Installing AUR packages..."
    yay -S --needed --noconfirm - < aurlist.txt
else
    echo "*****************************************"
    echo "Warning: aurlist.txt not found. Skipping AUR packages."
fi

# 7. Pull .config from GitHub and put shit where it belongs
# Replace the URL below with your actual repository link
GITHUB_REPO="https://github.com/Orphan-Crippler/archConfig.git"

echo "Pulling .config files from GitHub..."
git clone "$GITHUB_REPO" /tmp/dotfiles-config
mkdir -p "$HOME/.config"
cp -a /tmp/dotfiles-config/. "$HOME/.config/"
rm -rf /tmp/dotfiles-config
sudo mv "$HOME/.config/cloud/sddm.conf" /etc/
mkdir -p /usr/share/sddm/themes
sudo mv "$HOME/.config/cloud" /usr/share/sddm/themes/

# 8. Verify if zsh is installed and find its path
ZSH_PATH=$(command -v zsh)

# 9. Set shell to zsh
echo "========================================="
echo "           Set shell to zsh"
sudo chsh -s "$ZSH_PATH"

# 10. Install Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"


echo "========================================="
echo "       Setup & config complete!!!"
echo "========================================="
echo "    zsh & p10k need to be configured"
echo "========================================="
echo " Run hyprwhspr setup then reboot machine."
echo "========================================="

# The trap will automatically run here to clean up sudo access.
