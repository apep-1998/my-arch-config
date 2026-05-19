# my-arch-config — AI Agent Context

This file provides context for AI coding agents (Codex, Gemini, Cursor, etc.) working on this repository.

## What This Is

A single repository containing everything for an Arch Linux setup: the installer script, all dotfiles/configs, and a sync script. There is no separate dotfiles repo — everything lives here.

| Script | Purpose |
|--------|---------|
| `install.sh` | Run once on a fresh Arch machine (as root) — installs packages, applies configs |
| `sync.sh` | Run after `git pull` on any machine (as root) — re-applies symlinks, installs new packages |

## Supported Combinations

| Machine | Profile | User | Description |
|---------|---------|------|-------------|
| `pc` | `personal` | arsham | Desktop with AMD GPU + ROCm, personal tools |
| `pc` | `work` | everphone | Desktop with AMD GPU + ROCm, work tools |
| `laptop` | `personal` | arsham | Laptop with Intel GPU + battery mgmt, personal |
| `laptop` | `work` | everphone | Laptop with Intel GPU + battery mgmt, work |

## How Dotfiles Work

`~/dotfiles/` on any machine is a symlink to `<repo>/dotfiles/` — wherever the repo was cloned. Clone path doesn't matter. This means:
- Editing `~/.config/i3/config` edits the git-tracked file directly (through symlink chain)
- No separate dotfiles repo, no copy step, no manual sync

## Directory Structure

```
install.sh              fresh install script (run as root)
sync.sh                 pull + re-apply script (run as root)
base/
  packages.txt          pacman packages on every machine + profile
  aur-packages.txt      AUR packages on every machine + profile
machines/pc/
  packages.txt          AMD GPU drivers + full ROCm compute stack
  aur-packages.txt      AUR packages only for desktop PC
  setup.sh              post-install: ROCm env, video group
machines/laptop/
  packages.txt          Intel GPU drivers + TLP power management
  aur-packages.txt      AUR packages only for laptop (auto-cpufreq)
  setup.sh              post-install: TLP enable, video group
profiles/personal/
  packages.txt          Pacman packages for personal use
  aur-packages.txt      AUR packages for personal use
profiles/work/
  packages.txt          Pacman packages for work use (user: everphone)
  aur-packages.txt      AUR packages for work (slack-desktop)
dotfiles/
  zshrc                 Zsh config (symlinked to ~/.zshrc)
  p10k.zsh              Powerlevel10k config (copied to ~/.p10k.zsh)
  zsh_aliases           Shell aliases (copied to ~/.config/zsh_aliases)
  config/i3/            i3 window manager config + scripts + wallpapers
  config/polybar/       Polybar status bar config
  config/rofi/          Rofi launcher theme
  config/dunst/         Notification daemon config
  config/yazi/          TUI file manager config
  config/zed/           Zed editor settings
  config/opencode/      OpenCode AI assistant config
  config/bin/           Utility scripts (filemanager, audio, wifi helpers)
```

## Package File Format

```
# Comment — ignored
package-name
another-package

# Blank lines ignored too
```

`packages.txt` → `pacman -S --needed --noconfirm`
`aur-packages.txt` → `yay -S --needed --noconfirm` (run as non-root user)

## install.sh Flow (8 steps)

1. System update (`pacman -Syu`)
2. Enable multilib in `/etc/pacman.conf`
3. Install `base/packages.txt`
4. Install `machines/<machine>/packages.txt`
5. Bootstrap yay (build from AUR as non-root), then install:
   - `base/aur-packages.txt`
   - `machines/<machine>/aur-packages.txt`
   - `profiles/<profile>/aur-packages.txt`
6. Install `profiles/<profile>/packages.txt`
7. Set up dotfiles: symlink `~/dotfiles/` → `<repo>/dotfiles/`, create `~/.config/*` symlinks, copy p10k/zsh_aliases/greenclip, set shell to zsh
8. Enable systemd services (NetworkManager, sddm, bluetooth, tlp)

After install, saves `/etc/my-arch/profile` with machine/profile/username so `sync.sh` can read it.

## sync.sh Flow (3 steps)

1. `git pull --rebase` in the repo
2. Re-apply all `~/.config/*` symlinks (idempotent — picks up newly added apps)
3. Install any new packages from all applicable package files (using `--needed`, skips already installed)

## Mandatory Rules for Any Change

**After every change, update README.md to match.** The README is the human-facing source of truth.

Specific rules:
- New package → add to the most specific applicable layer; **always add a one-line comment directly above the package name** — no blank line between comment and package. Example:
  ```
  # fast file search (find alternative)
  fd
  # Slack team messaging desktop client
  slack-desktop
  ```
  Never add a package without a comment. Never use vague comments like `# utility` or `# tool`.
- New machine → full set of files + `select_option` entry in `install.sh` + README table + README section
- New profile → full set of files + `select_option` entry + `DEFAULT_USER` case + README table + README section
- Editing `install.sh` step order or count → update the step numbers in the script output AND in README
- Editing dotfiles → changes take effect immediately on the machine via symlinks (no separate sync needed)
- Never add `--noconfirm` to `pacman` without `--needed`
- Never run `yay` or `makepkg` as root — always `sudo -u "$USERNAME"`

## Key Technical Facts

- **yay bootstrap**: installed by building from AUR source as the target user, then `pacman -U` as root. Requires `go` pre-installed via pacman.
- **Intel GPU**: The laptop uses Intel Iris Xe (Raptor Lake 13th Gen i7-1370P). No `xf86-video-intel` — modesetting driver handles it. Packages: `mesa`, `lib32-mesa`, `vulkan-intel`, `intel-media-driver`.
- **AMD GPU**: The PC uses AMD Radeon. Packages: `vulkan-radeon`, `xf86-video-amdgpu`, `lib32-vulkan-radeon` + full ROCm stack.
- **Shell**: zsh with oh-my-zsh (`oh-my-zsh-git` from AUR), Powerlevel10k theme, zsh-autosuggestions + zsh-syntax-highlighting.
- **Display manager**: SDDM with `sddm-astronaut-theme` (AUR). Config at `/etc/sddm.conf`.
- **Dotfile symlinks**: `~/dotfiles/` → `<repo>/dotfiles/`. Each `dotfiles/config/<app>` is then symlinked to `~/.config/<app>`. `p10k.zsh`, `zsh_aliases`, and `greenclip.toml` are copied (not symlinked) because they may have per-machine modifications.
- **Keyboard layout**: Per-window layout tracking via `dotfiles/config/i3/scripts/i3-events/main.py` (Python async i3ipc). Lock screen always forces English (`us`) layout via `lock.sh` calling `setxkbmap` before `i3lock`.
- **Profile persistence**: Saved to `/etc/my-arch/profile` after install. `sync.sh` reads this so it knows which machine/profile to sync.
