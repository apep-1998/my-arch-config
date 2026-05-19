#!/bin/bash
# sync.sh — pull latest changes from git and re-apply everything
# Usage: sudo bash sync.sh
# Run this on any machine after pushing updates from another machine.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[SYNC]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

[ "$(id -u)" -eq 0 ] || { err "Run as root: sudo bash sync.sh"; exit 1; }

# ─── Load saved profile ───────────────────────────────────────────────────────
PROFILE_FILE="/etc/my-arch/profile"
if [ ! -f "$PROFILE_FILE" ]; then
    err "No saved profile at $PROFILE_FILE. Run install.sh first."
    exit 1
fi
source "$PROFILE_FILE"

HOME_DIR="/home/$USERNAME"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

log "Machine : $MACHINE"
log "Profile : $PROFILE"
log "User    : $USERNAME"
log "Repo    : $SCRIPT_DIR"
echo ""

# ─── Helper: install packages from a file ─────────────────────────────────────
install_pkg_file() {
    local file="$1"
    [ -f "$file" ] || return 0
    mapfile -t pkgs < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
    [ ${#pkgs[@]} -gt 0 ] || return 0
    log "Packages: $(basename "$(dirname "$file")")/$(basename "$file") (${#pkgs[@]})"
    pacman -S --needed --noconfirm "${pkgs[@]}"
}

install_aur_file() {
    local file="$1"
    local aur_user="$2"
    [ -f "$file" ] || return 0
    mapfile -t pkgs < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
    [ ${#pkgs[@]} -gt 0 ] || return 0
    log "AUR: $(basename "$file") (${#pkgs[@]})"
    sudo -u "$aur_user" yay -S --needed --noconfirm "${pkgs[@]}"
}

# ─── 1. Pull latest ───────────────────────────────────────────────────────────
step "1/3  Pull latest changes"
git -C "$SCRIPT_DIR" pull --rebase
log "Repository up to date"

# ─── 2. Re-apply dotfile symlinks ─────────────────────────────────────────────
step "2/3  Re-apply dotfile symlinks"

# ~/dotfiles -> repo/dotfiles (path-independent)
ln -sfn "$DOTFILES_DIR" "$HOME_DIR/dotfiles"
log "~/dotfiles -> $DOTFILES_DIR"

mkdir -p "$HOME_DIR/.config"

# Symlink each config subdirectory (idempotent — new apps picked up automatically)
for cfg_path in "$DOTFILES_DIR"/config/*/; do
    cfg=$(basename "$cfg_path")
    ln -sfn "$DOTFILES_DIR/config/$cfg" "$HOME_DIR/.config/$cfg"
    log "  -> ~/.config/$cfg"
done

[ -f "$DOTFILES_DIR/config/mimeapps.list" ] && \
    ln -sf "$DOTFILES_DIR/config/mimeapps.list" "$HOME_DIR/.config/mimeapps.list"

chmod +x "$DOTFILES_DIR"/config/bin/* 2>/dev/null || true

[ -f "$DOTFILES_DIR/zshrc" ] && \
    ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"

chown -h "$USERNAME:users" \
    "$HOME_DIR/dotfiles" \
    "$HOME_DIR/.zshrc" 2>/dev/null || true

# ─── 3. Install new packages ──────────────────────────────────────────────────
step "3/3  Install new packages (--needed = skips already installed)"

install_pkg_file "$SCRIPT_DIR/base/packages.txt"
install_pkg_file "$SCRIPT_DIR/machines/$MACHINE/packages.txt"
install_pkg_file "$SCRIPT_DIR/profiles/$PROFILE/packages.txt"
install_aur_file "$SCRIPT_DIR/base/aur-packages.txt" "$USERNAME"
install_aur_file "$SCRIPT_DIR/machines/$MACHINE/aur-packages.txt" "$USERNAME"
install_aur_file "$SCRIPT_DIR/profiles/$PROFILE/aur-packages.txt" "$USERNAME"

# Fix ownership
chown -R "$USERNAME:users" "$HOME_DIR/.config/" 2>/dev/null || true

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔═════════════════════════════════════╗"
echo "║  Sync complete!                     ║"
echo -e "╚═════════════════════════════════════╝${RESET}"
echo ""
echo "  If i3 is running, reload configs: Win+Shift+C"
