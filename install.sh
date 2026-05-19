#!/bin/bash
# install.sh — set up or update this machine
# First run: asks machine/profile/username, installs everything
# Later runs: loads saved profile, re-applies everything (idempotent)
# Usage: sudo bash install.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[OK]${RESET} $*"; }
warn() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
err()  { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
step() { echo -e "\n${BOLD}${CYAN}══ $* ══${RESET}"; }

[ "$(id -u)" -eq 0 ] || { err "Run as root: sudo bash install.sh"; exit 1; }

echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║        my-arch-config             ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${RESET}"

# ─── Helpers ──────────────────────────────────────────────────────────────────
select_option() {
    local prompt="$1"; shift
    local options=("$@")
    echo -e "${CYAN}$prompt${RESET}" >&2
    for i in "${!options[@]}"; do
        echo "  $((i+1))) ${options[$i]}" >&2
    done
    while true; do
        read -rp "Choice [1-${#options[@]}]: " choice <&2
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#options[@]} )); then
            echo "${options[$((choice-1))]}"
            return
        fi
        echo "Invalid choice, try again." >&2
    done
}

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

apply_hidden_apps() {
    local file="$1"
    local home_dir="$2"
    local user="$3"
    [ -f "$file" ] || return 0
    local apps_dir="$home_dir/.local/share/applications"
    sudo -u "$user" mkdir -p "$apps_dir"
    while IFS= read -r line; do
        [[ "$line" =~ ^\s*# ]] && continue
        [[ -z "${line// }" ]] && continue
        sudo -u "$user" tee "$apps_dir/${line}.desktop" > /dev/null <<EOF
[Desktop Entry]
Hidden=true
EOF
        log "  hidden: $line"
    done < "$file"
}

# ─── Load or collect profile ──────────────────────────────────────────────────
CALLING_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "")}"
PROFILE_FILE="/etc/my-arch/$CALLING_USER/profile"

if [ -f "$PROFILE_FILE" ]; then
    source "$PROFILE_FILE"
    echo -e "  Saved profile found for ${BOLD}$CALLING_USER${RESET}:"
    echo "    Machine : $MACHINE"
    echo "    Profile : $PROFILE"
    echo "    User    : $USERNAME"
    echo "    Repo    : $REPO_DIR"
    echo ""
    read -rp "  Continue? [Y/n] " confirm
    [[ "${confirm:-y}" =~ ^[Nn]$ ]] && { echo "Aborted."; exit 0; }
else
    MACHINE=$(select_option "Machine type:" "pc" "laptop")
    PROFILE=$(select_option "Profile:" "personal" "work")

    case "$PROFILE" in
        personal) DEFAULT_USER="${CALLING_USER:-arsham}" ;;
        work)     DEFAULT_USER="${CALLING_USER:-everphone}" ;;
    esac
    read -rp "Username [${DEFAULT_USER}]: " USERNAME
    USERNAME="${USERNAME:-$DEFAULT_USER}"

    echo ""
    echo "  Machine : $MACHINE"
    echo "  Profile : $PROFILE"
    echo "  User    : $USERNAME"
    echo "  Repo    : $SCRIPT_DIR"
    echo ""
    read -rp "  Proceed? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

HOME_DIR="/home/$USERNAME"
DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

# ─── 1. System update ─────────────────────────────────────────────────────────
step "1/7  System update"
pacman -Syu --noconfirm

# ─── 2. Multilib ──────────────────────────────────────────────────────────────
step "2/7  Multilib"
if ! grep -q '^\[multilib\]' /etc/pacman.conf; then
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' >> /etc/pacman.conf
    pacman -Sy --noconfirm
    log "Multilib enabled"
else
    log "Multilib already enabled"
fi

# ─── 3. Packages ──────────────────────────────────────────────────────────────
step "3/7  Packages"
install_pkg_file "$SCRIPT_DIR/base/packages.txt"
install_pkg_file "$SCRIPT_DIR/machines/$MACHINE/packages.txt"
install_pkg_file "$SCRIPT_DIR/profiles/$PROFILE/packages.txt"

# ─── 4. AUR packages ──────────────────────────────────────────────────────────
step "4/7  AUR packages"

pacman -S --needed --noconfirm go

if ! command -v yay &>/dev/null; then
    log "Building yay..."
    rm -rf /tmp/yay-build
    git clone https://aur.archlinux.org/yay.git /tmp/yay-build
    chown -R "$USERNAME:users" /tmp/yay-build
    sudo -u "$USERNAME" bash -c "cd /tmp/yay-build && makepkg --noconfirm"
    pacman -U --noconfirm /tmp/yay-build/yay-*.pkg.tar.zst
    rm -rf /tmp/yay-build
fi

# Allow the user to call pacman without a password for the duration of AUR installs.
# yay builds as the user then calls sudo pacman -U internally — without this it
# hangs waiting for a password with no TTY.
SUDOERS_FILE="/etc/sudoers.d/my-arch-aur-install"
echo "$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "$SUDOERS_FILE"
chmod 440 "$SUDOERS_FILE"

install_aur_file "$SCRIPT_DIR/base/aur-packages.txt" "$USERNAME"
install_aur_file "$SCRIPT_DIR/machines/$MACHINE/aur-packages.txt" "$USERNAME"
install_aur_file "$SCRIPT_DIR/profiles/$PROFILE/aur-packages.txt" "$USERNAME"

rm -f "$SUDOERS_FILE"
log "Removed temporary sudoers rule"

# ─── 5. Dotfiles ──────────────────────────────────────────────────────────────
step "5/7  Dotfiles"

sudo -u "$USERNAME" ln -sfn "$DOTFILES_DIR" "$HOME_DIR/dotfiles"
log "~/dotfiles -> $DOTFILES_DIR"

sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.config"

for cfg_path in "$DOTFILES_DIR"/config/*/; do
    cfg=$(basename "$cfg_path")
    sudo -u "$USERNAME" ln -sfn "$DOTFILES_DIR/config/$cfg" "$HOME_DIR/.config/$cfg"
    log "  -> ~/.config/$cfg"
done

[ -f "$DOTFILES_DIR/config/mimeapps.list" ] && \
    sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/config/mimeapps.list" "$HOME_DIR/.config/mimeapps.list"

chmod +x "$DOTFILES_DIR"/config/bin/* 2>/dev/null || true

[ -f "$DOTFILES_DIR/zshrc" ] && \
    sudo -u "$USERNAME" ln -sf "$DOTFILES_DIR/zshrc" "$HOME_DIR/.zshrc"

# Profile overlay
PROFILE_DOTFILES="$SCRIPT_DIR/profiles/$PROFILE/dotfiles"
if [ -d "$PROFILE_DOTFILES" ]; then
    [ -f "$PROFILE_DOTFILES/zsh_profile" ] && \
        sudo -u "$USERNAME" ln -sf "$PROFILE_DOTFILES/zsh_profile" "$HOME_DIR/.config/zsh_profile"
    [ -d "$PROFILE_DOTFILES/bin" ] && \
        sudo -u "$USERNAME" ln -sfn "$PROFILE_DOTFILES/bin" "$HOME_DIR/.config/profile-bin"
    chmod +x "$PROFILE_DOTFILES/bin/"* 2>/dev/null || true
    log "  -> profile overlay: zsh_profile + profile-bin"
fi

# Copied files (not symlinked — may have per-machine tweaks)
[ -f "$DOTFILES_DIR/p10k.zsh" ] && [ ! -f "$HOME_DIR/.p10k.zsh" ] && {
    cp "$DOTFILES_DIR/p10k.zsh" "$HOME_DIR/.p10k.zsh"
    chown "$USERNAME:users" "$HOME_DIR/.p10k.zsh"
}
[ -f "$DOTFILES_DIR/zsh_aliases" ] && {
    cp "$DOTFILES_DIR/zsh_aliases" "$HOME_DIR/.config/zsh_aliases"
    chown "$USERNAME:users" "$HOME_DIR/.config/zsh_aliases"
}
[ -f "$DOTFILES_DIR/greenclip.toml" ] && {
    cp "$DOTFILES_DIR/greenclip.toml" "$HOME_DIR/.config/greenclip.toml"
    chown "$USERNAME:users" "$HOME_DIR/.config/greenclip.toml"
}

sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.cache/oh-my-zsh"
sudo -u "$USERNAME" mkdir -p "$HOME_DIR/.config/autorandr"

chsh -s /bin/zsh "$USERNAME"

# ─── 6. App visibility ────────────────────────────────────────────────────────
step "6/7  App visibility"
apply_hidden_apps "$SCRIPT_DIR/profiles/$PROFILE/hidden-apps.txt" "$HOME_DIR" "$USERNAME"

# Machine + profile post-config hooks
[ -f "$SCRIPT_DIR/machines/$MACHINE/setup.sh" ] && \
    bash "$SCRIPT_DIR/machines/$MACHINE/setup.sh" "$USERNAME"
[ -f "$SCRIPT_DIR/profiles/$PROFILE/setup.sh" ] && \
    bash "$SCRIPT_DIR/profiles/$PROFILE/setup.sh" "$USERNAME"

# ─── 7. Services ──────────────────────────────────────────────────────────────
step "7/7  Services"
systemctl enable NetworkManager
systemctl enable sddm
systemctl enable bluetooth 2>/dev/null || warn "bluetooth service not found"

[ "$MACHINE" = "laptop" ] && systemctl list-unit-files | grep -q tlp && {
    systemctl enable tlp
    systemctl enable tlp-sleep
}

# ─── Save profile ─────────────────────────────────────────────────────────────
# Keyed by CALLING_USER (who ran sudo) so the lookup at the top always matches
mkdir -p "/etc/my-arch/$CALLING_USER"
cat > "/etc/my-arch/$CALLING_USER/profile" <<EOF
MACHINE=$MACHINE
PROFILE=$PROFILE
USERNAME=$USERNAME
REPO_DIR=$SCRIPT_DIR
EOF

chown -R "$USERNAME:users" "$HOME_DIR/"

# ─── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗"
echo "║  Done!                               ║"
echo -e "╚══════════════════════════════════════╝${RESET}"
echo ""
echo "  Machine : $MACHINE"
echo "  Profile : $PROFILE"
echo "  User    : $USERNAME"
echo ""
echo "  Next: git pull && sudo bash install.sh"
