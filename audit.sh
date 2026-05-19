#!/bin/bash
# audit.sh — find packages installed on this machine but not tracked in the config
# Outputs files to ~/my-arch-audit/ ready to feed to an LLM
# Usage: bash audit.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CYAN='\033[0;36m'; GREEN='\033[1;32m'; BOLD='\033[1m'; RESET='\033[0m'

log()  { echo -e "${GREEN}[audit]${RESET} $*"; }
info() { echo -e "${CYAN}$*${RESET}"; }

# ─── Load profile ─────────────────────────────────────────────────────────────
CALLING_USER="${SUDO_USER:-$USER}"
PROFILE_FILE="/etc/my-arch/$CALLING_USER/profile"

if [ ! -f "$PROFILE_FILE" ]; then
    echo "No saved profile found at $PROFILE_FILE."
    echo "Run: sudo bash install.sh"
    exit 1
fi
source "$PROFILE_FILE"

log "Machine : $MACHINE"
log "Profile : $PROFILE"
log "User    : $USERNAME"
echo ""

# ─── Collect tracked packages from config ─────────────────────────────────────
declare -A tracked_official
declare -A tracked_aur

for file in \
    "$SCRIPT_DIR/base/packages.txt" \
    "$SCRIPT_DIR/machines/$MACHINE/packages.txt" \
    "$SCRIPT_DIR/profiles/$PROFILE/packages.txt"; do
    [ -f "$file" ] || continue
    while IFS= read -r pkg; do
        tracked_official["$pkg"]=1
    done < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
done

for file in \
    "$SCRIPT_DIR/base/aur-packages.txt" \
    "$SCRIPT_DIR/machines/$MACHINE/aur-packages.txt" \
    "$SCRIPT_DIR/profiles/$PROFILE/aur-packages.txt"; do
    [ -f "$file" ] || continue
    while IFS= read -r pkg; do
        tracked_aur["$pkg"]=1
    done < <(grep -v '^\s*#' "$file" | grep -v '^\s*$')
done

log "Tracked official : ${#tracked_official[@]} packages"
log "Tracked AUR      : ${#tracked_aur[@]} packages"

# ─── Get explicitly installed packages from system ────────────────────────────
# -Qe = explicitly installed (not pulled in as dependency)
# -Qn = native (official repos)   -Qm = foreign (AUR)
mapfile -t installed_official < <(pacman -Qen | awk '{print $1}' | sort)
mapfile -t installed_aur      < <(pacman -Qem 2>/dev/null | awk '{print $1}' | sort)

log "Installed official: ${#installed_official[@]} packages"
log "Installed AUR     : ${#installed_aur[@]} packages"

# ─── Find untracked packages ──────────────────────────────────────────────────
untracked_official=()
for pkg in "${installed_official[@]}"; do
    [[ -z "${tracked_official[$pkg]+x}" ]] && untracked_official+=("$pkg")
done

untracked_aur=()
for pkg in "${installed_aur[@]}"; do
    [[ -z "${tracked_aur[$pkg]+x}" ]] && untracked_aur+=("$pkg")
done

# ─── Write output files ───────────────────────────────────────────────────────
OUT_DIR="$HOME/my-arch-audit"
mkdir -p "$OUT_DIR"

printf '%s\n' "${installed_official[@]}" > "$OUT_DIR/installed-official.txt"
printf '%s\n' "${installed_aur[@]}"      > "$OUT_DIR/installed-aur.txt"
printf '%s\n' "${untracked_official[@]}" > "$OUT_DIR/untracked-official.txt"
printf '%s\n' "${untracked_aur[@]}"      > "$OUT_DIR/untracked-aur.txt"

# ─── Summary for LLM ──────────────────────────────────────────────────────────
cat > "$OUT_DIR/summary.md" <<EOF
# my-arch-config audit — $(date '+%Y-%m-%d')

## Machine info
- Machine : $MACHINE
- Profile : $PROFILE
- User    : $USERNAME
- Repo    : $SCRIPT_DIR

## What this is
These files list packages installed on this machine that are not tracked
in the my-arch-config project. They represent software installed manually
over time that hasn't been added to the config yet.

## Files
- \`untracked-official.txt\` — ${#untracked_official[@]} official packages not in config
- \`untracked-aur.txt\`      — ${#untracked_aur[@]} AUR packages not in config
- \`installed-official.txt\` — all ${#installed_official[@]} explicitly installed official packages
- \`installed-aur.txt\`      — all ${#installed_aur[@]} explicitly installed AUR packages

## Untracked official packages (${#untracked_official[@]})
$(printf '- %s\n' "${untracked_official[@]}")

## Untracked AUR packages (${#untracked_aur[@]})
$(printf '- %s\n' "${untracked_aur[@]}")

## Task for LLM
Review the untracked packages above. For each one:
1. Decide if it belongs in: base/, machines/$MACHINE/, or profiles/$PROFILE/
2. Add it to the correct packages.txt or aur-packages.txt with a one-line comment
3. If it's not useful to keep, ignore it

Current profile config files for reference:
- base/packages.txt
- machines/$MACHINE/packages.txt
- profiles/$PROFILE/packages.txt
- base/aur-packages.txt
- machines/$MACHINE/aur-packages.txt
- profiles/$PROFILE/aur-packages.txt
EOF

# ─── Print summary ────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗"
echo "║  Audit complete                      ║"
echo -e "╚══════════════════════════════════════╝${RESET}"
echo ""
info "  Untracked official : ${#untracked_official[@]}"
info "  Untracked AUR      : ${#untracked_aur[@]}"
echo ""
echo "  Output: $OUT_DIR/"
echo "    installed-official.txt  — all explicitly installed official packages"
echo "    installed-aur.txt       — all explicitly installed AUR packages"
echo "    untracked-official.txt  — official packages NOT in your config"
echo "    untracked-aur.txt       — AUR packages NOT in your config"
echo "    summary.md              — paste this into an LLM"
echo ""
