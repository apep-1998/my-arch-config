# Arch Linux Installer

A modular, interactive Arch Linux post-install script that sets up a full i3-based desktop environment. It combines a shared base with machine-specific and profile-specific layers so the same codebase covers a desktop PC, a laptop, a personal setup, and a work setup — with no duplication.

---

## How It Works

Running `sudo bash install.sh` presents an interactive prompt that asks three questions:

1. **Machine type** — `pc` or `laptop`
2. **Profile** — `personal` or `work`
3. **Username** — who to configure (defaults to `arsham` for personal, `everphone` for work)

It then installs packages and applies configs in this order:

```
base packages
  + machine packages       (pc = AMD/ROCm, laptop = Intel GPU + TLP)
  + base AUR packages
  + machine AUR packages
  + profile packages
  + profile AUR packages
  → dotfiles + symlinks
  → system services
```

Everything is additive — each layer only adds what it specifically needs.

---

## Project Structure

```
arch-installer/
├── install.sh                  ← main entry point
│
├── base/
│   ├── packages.txt            ← pacman packages on every machine
│   └── aur-packages.txt        ← AUR packages on every machine
│
├── machines/
│   ├── pc/
│   │   ├── packages.txt        ← AMD GPU + ROCm (official repos)
│   │   ├── aur-packages.txt    ← PC-only AUR packages
│   │   └── setup.sh            ← post-install: ROCm env vars, video group
│   └── laptop/
│       ├── packages.txt        ← Intel GPU + TLP power management
│       ├── aur-packages.txt    ← laptop-only AUR (auto-cpufreq)
│       └── setup.sh            ← post-install: TLP enable, video group
│
├── profiles/
│   ├── personal/
│   │   ├── packages.txt        ← personal-only pacman packages
│   │   └── aur-packages.txt    ← personal-only AUR packages
│   └── work/
│       ├── packages.txt        ← work-only pacman packages
│       └── aur-packages.txt    ← work-only AUR (slack-desktop)
│
└── dotfiles/                   ← bundled copy of all configs
    ├── zshrc                   ← symlinked to ~/.zshrc
    ├── p10k.zsh                ← copied to ~/.p10k.zsh
    ├── zsh_aliases             ← copied to ~/.config/zsh_aliases
    ├── greenclip.toml          ← copied to ~/.config/greenclip.toml
    └── config/
        ├── i3/                 ← symlinked to ~/.config/i3
        ├── polybar/            ← symlinked to ~/.config/polybar
        ├── rofi/               ← symlinked to ~/.config/rofi
        ├── dunst/              ← symlinked to ~/.config/dunst
        ├── kitty/              ← symlinked to ~/.config/kitty
        ├── yazi/               ← symlinked to ~/.config/yazi
        ├── zed/                ← symlinked to ~/.config/zed
        └── opencode/           ← symlinked to ~/.config/opencode
```

---

## Package Files Format

All `packages.txt` and `aur-packages.txt` files use the same format:

- One package name per line
- Lines starting with `#` are comments and are ignored
- Blank lines are ignored

```
# This is a comment
kitty
firefox

# Another section
bat
fd
```

`packages.txt` → installed via `pacman -S --needed`
`aur-packages.txt` → installed via `yay -S --needed`

---

## Machine Profiles

### PC (`machines/pc/`)
- **GPU**: AMD (Radeon) — `vulkan-radeon`, `xf86-video-amdgpu`
- **Compute**: Full ROCm stack for AI/ML — `rocm-hip-sdk`, `rocblas`, `miopen-hip`, etc.
- **Post-setup**: Adds ROCm to `$PATH` and `$LD_LIBRARY_PATH`, adds user to `video` group

### Laptop (`machines/laptop/`)
- **GPU**: Intel Iris Xe (Raptor Lake 13th Gen) — `vulkan-intel`, `intel-media-driver`
- **Power**: TLP + `auto-cpufreq` for battery management
- **Post-setup**: Enables TLP service, adds user to `video` group for backlight control

---

## User Profiles

### Personal (`profiles/personal/`)
- Default user: `arsham`
- Focused on dev tools and AI tools

### Work (`profiles/work/`)
- Default user: `everphone`
- Adds `slack-desktop` and work-oriented tools

---

## Dotfiles Setup

The `dotfiles/` directory is a bundled snapshot of the actual config files. When the installer runs, it:

1. Copies the entire `dotfiles/` directory to `~/dotfiles/` for the target user
2. Creates symlinks from `~/.config/<app>` → `~/dotfiles/config/<app>` for each app
3. Copies `p10k.zsh`, `zsh_aliases`, and `greenclip.toml` directly (not symlinked)
4. Symlinks `~/.zshrc` → `~/dotfiles/zshrc`

Alternatively, if you provide a git URL when prompted, the installer will `git clone` that URL instead of copying the bundled files. This is useful for keeping dotfiles in sync with a remote repo.

---

## Installed Software

### Desktop Environment
- **WM**: i3-wm with i3blocks, i3lock, i3status-rust
- **Bar**: Polybar
- **Launcher**: Rofi + rofi-pass (password manager) + rofi-greenclip (clipboard)
- **Notifications**: Dunst
- **Display manager**: SDDM with sddm-astronaut-theme
- **Terminal**: Kitty + Gnome Terminal

### Shell
- **Shell**: Zsh with oh-my-zsh
- **Theme**: Powerlevel10k
- **Plugins**: zsh-autosuggestions, zsh-syntax-highlighting

### Applications
- **Browsers**: Firefox, Brave, Google Chrome
- **Editor**: Zed
- **File manager**: Yazi (TUI)
- **Image viewer**: nsxiv
- **AI tools**: Claude Code, OpenCode, Gemini CLI
- **Media**: playerctl, pulsemixer, pasystray, blueman, wiremix

### Fonts
Full Nerd Fonts collection (all `ttf-*-nerd` and `otf-*-nerd` packages) plus Noto CJK/emoji.

---

## Adding a New Machine

1. Create `machines/<name>/packages.txt`
2. Create `machines/<name>/aur-packages.txt`
3. Create `machines/<name>/setup.sh` (optional, for post-install steps)
4. Add `"<name>"` to the `select_option` call in `install.sh`
5. **Update this README**

## Adding a New Profile

1. Create `profiles/<name>/packages.txt`
2. Create `profiles/<name>/aur-packages.txt`
3. Create `profiles/<name>/setup.sh` (optional)
4. Add `"<name>"` to the `select_option` call and the `DEFAULT_USER` case in `install.sh`
5. **Update this README**

## Adding Packages

- Official repo package → add to the appropriate `packages.txt`
- AUR package → add to the appropriate `aur-packages.txt`
- If it belongs everywhere: `base/`
- If it's GPU/hardware-specific: `machines/<machine>/`
- If it's only for one use case: `profiles/<profile>/`

---

## Usage

```bash
# On a fresh Arch install, after base system is set up:
git clone <this-repo-url> ~/arch-installer
cd ~/arch-installer
sudo bash install.sh
```

You will be asked to choose machine type, profile, and username. The install takes 10–30 minutes depending on internet speed (nerd fonts and browsers are large downloads).

After install:
1. Reboot
2. Log in via SDDM
3. Run `autorandr --save <hostname>` to save your display layout
