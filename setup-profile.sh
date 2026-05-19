#!/bin/bash
# setup-profile.sh — register this machine's profile
# Run this once on any existing machine to enable sync.sh
# Usage: bash setup-profile.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'; GREEN='\033[1;32m'; BOLD='\033[1m'; RESET='\033[0m'

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

echo -e "${BOLD}"
echo "  ╔═══════════════════════════════════╗"
echo "  ║     my-arch-config profile setup  ║"
echo "  ╚═══════════════════════════════════╝"
echo -e "${RESET}"

MACHINE=$(select_option "Machine type:" "pc" "laptop")
PROFILE=$(select_option "Profile:" "personal" "work")

case "$PROFILE" in
    personal) DEFAULT_USER="arsham" ;;
    work)     DEFAULT_USER="everphone" ;;
esac

read -rp "Username [${DEFAULT_USER}]: " USERNAME
USERNAME="${USERNAME:-$DEFAULT_USER}"

echo ""
echo -e "${GREEN}Writing /etc/my-arch/profile (needs sudo)...${RESET}"

sudo mkdir -p /etc/my-arch
sudo tee /etc/my-arch/profile > /dev/null <<EOF
MACHINE=$MACHINE
PROFILE=$PROFILE
USERNAME=$USERNAME
REPO_DIR=$SCRIPT_DIR
EOF

echo -e "${GREEN}Done.${RESET}"
echo ""
echo "  Machine : $MACHINE"
echo "  Profile : $PROFILE"
echo "  User    : $USERNAME"
echo "  Repo    : $SCRIPT_DIR"
echo ""
echo "You can now run: sudo bash $SCRIPT_DIR/sync.sh"
