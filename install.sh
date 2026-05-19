#!/bin/bash
# Arch Linux installer — part of my-arch-config
# Usage: sudo bash install.sh
# Combines: base + machine (pc|laptop) + profile (personal|work)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[INSTALL]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

# ─── Root check ───────────────────────────────────────────────────────────────
[ "$(id -u)" -eq 0 ] || { err "Run as root: sudo bash install.sh"; exit 1; }

# ─── Interactive selection ─────────────────────────────────────────────────────
echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║     Arch Linux Installer          ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${RESET}"

select_option() {
    local prompt="$1"; shift
    local options=("$@")
    echo -e "${CYAN}$prompt${RESET}"
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}"
    done
    while true; do
        read -rp "Choice [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice-1))]}"
            return
        fi
        echo "Invalid choice, try again."
    done
}

MACHINE=$(select_option "Machine type:" "pc" "laptop")
PROFILE=$(select_option "Profile:" "personal" "work")

# Default usernames per profile
case "$PROFILE" in
    personal) DEFAULT_USER="arsham" ;;
    work)     DEFAULT_USER="everphone" ;;
esac

read -rp "Username [${DEFAULT_USER}]: " USERNAME
USERNAME="${USERNAME:-$DEFAULT_USER}"

echo ""
log "Machine : $MACHINE"
log "Profile : $PROFILE"
log "User    : $USERNAME"
log "Repo    : $SCRIPT_DIR"
echo ""
read -rp "Proceed? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ─── Helper: install packages from a file ─────────────────────────────────────
install_pkg_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    mapfile -t pkgs < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
    [ ${#pkgs[@]} -gt 0 ] || return 0
    log "Installing from $(basename "$(dirname "$file")")/$(basename "$file") (${#pkgs[@]} packages)"
    pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur_file() {
    local file="$1"
    local aur_user="$2"
    [ -f "$file" ] || return 0
    mapfile -t pkgs < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
    [ ${#pkgs[@]} -gt 0 ] || return 0
    log "Installing AUR packages from $(basename "$file") (${#pkgs[@]} packages)"
    sudo -u "$aur_user" yay -S --needed --noconfirm "${pkgs[@]}"
}

# ─── 1. System update ─────────────────────────────────────────────────────────
step "1/8  System update"
pacman -Syu --noconfirm

# ─── 2. Multilib ──────────────────────────────────────────────────────────────
step "2/8  Multilib"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
    pacman -Sy --noconfirm
fi

# ─── 3. Base packages ─────────────────────────────────────────────────────────
step "3/8  Base packages"
install_pkg_file "$SCRIPT_DIR/base/packages.txt"

# ─── 4. Machine-specific packages ─────────────────────────────────────────────
step "4/8  Machine packages ($MACHINE)"
install_pkg_file "$SCRIPT_DIR/machines/$MACHINE/packages.txt"

# ─── 5. yay + AUR packages ────────────────────────────────────────────────────
step "5/8  AUR packages"

# Ensure go is installed (yay build dep)
pacman -S --needed --noconfirm go

# Build yay if missing
if ! command -v yay &>/dev/null; then
    log "Building yay..."
    rm -rf /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    chown -R "$USERNAME:users" /tmp/yay-build
    sudo -u "$USERNAME" bash -c "cd /tmp/yay-build && makepkg --noconfirm"
    pacman -U --noconfirm /tmp/yay-build/yay-*.pkg.tar.zst
    rm -rf /tmp/yay-build
fi

# Base AUR packages
install_aur_file "$SCRIPT_DIR/base/aur-packages.txt" "$USERNAME"

# Machine AUR packages
install_aur_file "$SCRIPT_DIR/machines/$MACHINE/aur-packages.txt" "$USERNAME"

# Profile AUR packages
install_aur_file "$SCRIPT_DIR/profiles/$PROFILE/aur-packages.txt" "$USERNAME"

# ─── 6. Profile packages ──────────────────────────────────────────────────────
step "6/8  Profile packages ($PROFILE)"
install_pkg_file "$SCRIPT_DIR/profiles/$PROFILE/packages.txt"

# ─── 7. Dotfiles + configs ────────────────────────────────────────────────────
step "7/8  Dotfiles and configs"

HOME_DIR="/home/$USERNAME"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ~/dotfiles is a symlink into this repo — path-independent regardless of clone location
sudo -u "$USERNAME" ln -sfn "$DOTFILES_DIR" "$HOME_DIR/dotfiles"
log "Linked ~/dotfiles -> $DOTFILES_DIR"

sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.config"

# Symlink each config subdirectory
for cfg_path in "$DOTFILES_DIR"/config/*/; do
    cfg=$(basename "$cfg_path")
    sudo -u "$USERNAME" ln -sfn "$DOTFILES_DIR/config/$cfg" "$HOME_DIR/.config/$cfg"
    log "  -> ~/.config/$cfg"
done

# mimeapps.list
[ -f "$DOTFILES_DIR/config/mimeapps.list" ] && \
    sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/config/mimeapps.list" "$HOME_DIR/.config/mimeapps.list"

# make bin scripts executable
chmod +x "$DOTFILES_DIR"/config/bin/* 2>/dev/null || true

# .zshrc
[ -f "$DOTFILES_DIR/zshrc" ] && \
    sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"

# Profile-specific dotfiles overlay
PROFILE_DOTFILES="$SCRIPT_DIR/profiles/$PROFILE/dotfiles"
if [ -d "$PROFILE_DOTFILES" ]; then
    # zsh_profile — sourced at end of zshrc for profile-specific config
    [ -f "$PROFILE_DOTFILES/zsh_profile" ] && \
        sudo -u "$USERNAME" ln -sf "$PROFILE_DOTFILES/zsh_profile" "$HOME_DIR/.config/zsh_profile"
    # profile-specific bin — separate from base bin, added to PATH via zsh_profile
    [ -d "$PROFILE_DOTFILES/bin" ] && \
        sudo -u "$USERNAME" ln -sfn "$PROFILE_DOTFILES/bin" "$HOME_DIR/.config/profile-bin"
    chmod +x "$PROFILE_DOTFILES/bin/"* 2>/dev/null || true
    log "  -> profile overlay: zsh_profile + profile-bin"
fi

# p10k — copied (not symlinked) so it can have per-user tweaks
if [ -f "$DOTFILES_DIR/p10k.zsh" ] && [ ! -f "$HOME_DIR/.p10k.zsh" ]; then
    cp "$DOTFILES_DIR/p10k.zsh" "$HOME_DIR/.p10k.zsh"
    chown "$USERNAME:users" "$HOME_DIR/.p10k.zsh"
fi

# zsh_aliases — copied so each machine can have local overrides
if [ -f "$DOTFILES_DIR/zsh_aliases" ]; then
    cp "$DOTFILES_DIR/zsh_aliases" "$HOME_DIR/.config/zsh_aliases"
    chown "$USERNAME:users" "$HOME_DIR/.config/zsh_aliases"
fi

# greenclip config — copied (contains machine-specific history path)
if [ -f "$DOTFILES_DIR/greenclip.toml" ]; then
    cp "$DOTFILES_DIR/greenclip.toml" "$HOME_DIR/.config/greenclip.toml"
    chown "$USERNAME:users" "$HOME_DIR/.config/greenclip.toml"
fi

# oh-my-zsh cache and misc dirs
sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.cache/oh-my-zsh"
sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.config/bin"
sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.config/autorandr"

# Set shell to zsh
chsh -s /bin/zsh "$USERNAME"

# Machine-specific post-config
if [ -f "$SCRIPT_DIR/machines/$MACHINE/setup.sh" ]; then
    log "Running machine-specific setup..."
    bash "$SCRIPT_DIR/machines/$MACHINE/setup.sh" "$USERNAME"
fi

# Profile-specific post-config
if [ -f "$SCRIPT_DIR/profiles/$PROFILE/setup.sh" ]; then
    log "Running profile-specific setup..."
    bash "$SCRIPT_DIR/profiles/$PROFILE/setup.sh" "$USERNAME"
fi

# Save profile so sync.sh can read it without asking again
mkdir -p /etc/my-arch
cat > /etc/my-arch/profile <<EOF
MACHINE=$MACHINE
PROFILE=$PROFILE
USERNAME=$USERNAME
REPO_DIR=$SCRIPT_DIR
EOF
log "Saved profile to /etc/my-arch/profile"

# ─── 8. Services ──────────────────────────────────────────────────────────────
step "8/8  System services"

systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth 2>/dev/null || warn "bluetooth service not found"

# Laptop: enable power management
if [ "$MACHINE" = "laptop" ] && systemctl list-unit-files | grep -q tlp; then
    systemctl enable tlp
    systemctl enable tlp-sleep
fi

# Fix permissions
chown -R "$USERNAME:users" "$HOME_DIR/"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗"
echo "║  Installation complete!              ║"
echo -e "╚══════════════════════════════════════╝${RESET}"
echo ""
echo "  Machine : $MACHINE"
echo "  Profile : $PROFILE"
echo "  User    : $USERNAME"
echo "  Dotfiles: $DOTFILES_DIR"
echo ""
echo "Next steps:"
echo "  1. Reboot"
echo "  2. Log in via SDDM"
echo "  3. Run: autorandr --save $(hostname)"
echo ""
echo "To sync updates later: sudo bash $SCRIPT_DIR/sync.sh"
