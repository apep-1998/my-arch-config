# my-arch-config

Everything for my Arch Linux setup in one place: installer, dotfiles, and sync script. Clone it anywhere, run `install.sh` once, and you're done. After that, `sync.sh` keeps any machine up to date with a single command.

---

## How It Works

```bash
git clone <repo> ~/.my-arch-config   # or any path you want
cd ~/.my-arch-config
sudo bash install.sh
```

**First run** — asks three questions, then installs everything:

1. **Machine type** — `pc` or `laptop`
2. **Profile** — `personal` or `work`
3. **Username** — who to configure

**Every run after that** — loads the saved profile automatically, just asks "Continue?", then re-applies everything. Already-installed packages are skipped, new ones are installed, new symlinks are created.

```
packages (base + machine + profile)   ← --needed, skips already installed
→ dotfiles symlinked into ~/dotfiles/  ← idempotent, picks up new apps
→ app visibility (hidden-apps.txt)
→ system services
```

### Keeping machines in sync

After pulling updates from another machine:

```bash
git pull
sudo bash install.sh
```

---

## Project Structure

```
my-arch-config/
├── install.sh                  ← run this always (fresh install or update)
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
└── dotfiles/                   ← all configs live here
    ├── zshrc                   ← symlinked to ~/.zshrc
    ├── p10k.zsh                ← copied to ~/.p10k.zsh
    ├── zsh_aliases             ← copied to ~/.config/zsh_aliases
    └── config/
        ├── i3/                 ← symlinked to ~/.config/i3
        ├── polybar/            ← symlinked to ~/.config/polybar
        ├── rofi/               ← symlinked to ~/.config/rofi
        ├── dunst/              ← symlinked to ~/.config/dunst
        ├── kitty/              ← symlinked to ~/.config/kitty
        ├── yazi/               ← symlinked to ~/.config/yazi
        ├── zed/                ← symlinked to ~/.config/zed
        ├── opencode/           ← symlinked to ~/.config/opencode
        └── bin/                ← symlinked to ~/.config/bin (utility scripts)
```

---

## How Dotfiles Work

After install, `~/dotfiles/` is a **symlink into the repo** — wherever you cloned it:

```
~/.config/i3/  →  ~/dotfiles/config/i3/  →  ~/.my-arch-config/dotfiles/config/i3/
```

Editing any config file edits the file in the git repo directly. No separate dotfiles repo, no manual sync. Just edit → commit → push → `sync.sh` on other machines.

---

## Package File Format

One package per line. Every package has a `#` comment on the line directly above it:

```
# fast file search (find alternative)
fd
# Slack team messaging desktop client
slack-desktop
```

- `packages.txt` → installed via `pacman -S --needed`
- `aur-packages.txt` → installed via `yay -S --needed`

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

## Installed Software

### Desktop Environment
- **WM**: i3-wm with i3blocks, i3lock, i3status-rust
- **Bar**: Polybar — battery + backlight modules auto-appear on the laptop (detected by `launch.sh` via `/sys/class/power_supply/BAT*` and `/sys/class/backlight/`). Scrolling on the `BRI` module adjusts brightness via `brightnessctl` (the Intel iGPU here doesn't expose a RandR Backlight property, so `xbacklight` can't drive it).
- **Launcher**: Rofi + rofi-pass (password manager) + rofi-greenclip (clipboard history, `mod+c`)
- **Notifications**: Dunst
- **Display manager**: SDDM with sddm-astronaut-theme
- **Terminal**: Kitty

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
- **Dev**: git, github-cli, docker, go, python, node

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
3. Add `"<name>"` to the `select_option` call and the `DEFAULT_USER` case in `install.sh`
4. **Update this README**

## Adding Packages

- Official repo package → add to the appropriate `packages.txt`
- AUR package → add to the appropriate `aur-packages.txt`
- Needed everywhere → `base/`
- GPU/hardware-specific → `machines/<machine>/`
- Only for one use case → `profiles/<profile>/`

Always add a one-line `#` comment on the line directly above the package name.

---

## After Install

1. Reboot
2. Log in via SDDM
3. Run `autorandr --save $(hostname)` to save your display layout

To apply updates from another machine later:
```bash
git pull
sudo bash install.sh
```
