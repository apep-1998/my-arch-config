# Arch Linux Installer — AI Agent Context

This file provides context for AI coding agents (Codex, Gemini, Cursor, etc.) working on this repository.

## What This Is

A modular Arch Linux post-install script that sets up a full i3-based desktop environment. The entry point is `install.sh`. It is interactive: it asks for a machine type and profile, then installs the right combination of packages and applies dotfiles.

## Combinations Supported

| Machine | Profile | User | Description |
|---------|---------|------|-------------|
| `pc` | `personal` | arsham | Desktop with AMD GPU + ROCm, personal tools |
| `pc` | `work` | everphone | Desktop with AMD GPU + ROCm, work tools |
| `laptop` | `personal` | arsham | Laptop with Intel GPU + battery mgmt, personal |
| `laptop` | `work` | everphone | Laptop with Intel GPU + battery mgmt, work |

## Directory Structure and What Goes Where

```
base/
  packages.txt          pacman packages installed on every machine + profile
  aur-packages.txt      AUR packages installed on every machine + profile

machines/pc/
  packages.txt          AMD GPU drivers + full ROCm compute stack
  aur-packages.txt      AUR packages only needed on the desktop PC
  setup.sh              Bash script run after packages; sets ROCm env, video group

machines/laptop/
  packages.txt          Intel GPU drivers + TLP power management
  aur-packages.txt      AUR packages only needed on the laptop (auto-cpufreq)
  setup.sh              Bash script run after packages; enables TLP, video group

profiles/personal/
  packages.txt          Pacman packages for personal use
  aur-packages.txt      AUR packages for personal use

profiles/work/
  packages.txt          Pacman packages for work use (user: everphone)
  aur-packages.txt      AUR packages for work use (slack-desktop)

dotfiles/
  zshrc                 Zsh config (symlinked to ~/.zshrc)
  p10k.zsh              Powerlevel10k config (copied to ~/.p10k.zsh)
  zsh_aliases           Shell aliases (copied to ~/.config/zsh_aliases)
  greenclip.toml        Clipboard manager config (copied, path-substituted)
  config/i3/            i3 window manager config + scripts + wallpapers
  config/polybar/       Polybar status bar config
  config/rofi/          Rofi launcher theme
  config/dunst/         Notification daemon config
  config/yazi/          TUI file manager config
  config/zed/           Zed editor settings
  config/opencode/      OpenCode AI assistant config
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
7. Set up dotfiles: copy `dotfiles/` to `~/dotfiles/`, create symlinks, set shell to zsh
8. Enable systemd services (NetworkManager, sddm, bluetooth, tlp)

## Mandatory Rules for Any Change

**After every change, update README.md to match.** The README is the human-facing source of truth. If you add a machine, profile, package, or change any behavior, the README must reflect it.

Specific rules:
- New package → add to the most specific applicable layer; document what it is and why in a comment in the package file
- New machine → full set of files + `select_option` entry in `install.sh` + README table + README section
- New profile → full set of files + `select_option` entry + `DEFAULT_USER` case + README table + README section
- Editing `install.sh` step order or count → update the step numbers in the script output AND in README
- Editing dotfiles → note that `dotfiles/` here is a snapshot; the live files on the machine are separate
- Never add `--noconfirm` to `pacman` without `--needed`
- Never run `yay` or `makepkg` as root — always `sudo -u "$USERNAME"`

## Key Technical Facts

- **yay bootstrap**: installed by building from AUR source as the target user, then `pacman -U` as root. Requires `go` pre-installed via pacman.
- **Intel GPU**: The laptop uses Intel Iris Xe (Raptor Lake 13th Gen i7-1370P). No `xf86-video-intel` — modesetting driver handles it. Packages: `mesa`, `lib32-mesa`, `vulkan-intel`, `intel-media-driver`.
- **AMD GPU**: The PC uses AMD Radeon. Packages: `vulkan-radeon`, `xf86-video-amdgpu`, `lib32-vulkan-radeon` + full ROCm stack.
- **Shell**: zsh with oh-my-zsh (`oh-my-zsh-git` from AUR), Powerlevel10k theme, zsh-autosuggestions + zsh-syntax-highlighting.
- **Display manager**: SDDM with `sddm-astronaut-theme` (AUR). Config at `/etc/sddm.conf`.
- **Dotfile symlinks**: Each `dotfiles/config/<app>` is symlinked to `~/.config/<app>`. `p10k.zsh`, `zsh_aliases`, and `greenclip.toml` are copied (not symlinked) because they may have per-user modifications.
