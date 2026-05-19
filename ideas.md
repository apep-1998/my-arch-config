# Arch Linux Config Ideas

Things I don't have yet but worth considering. Organized by category.

---

## Terminal & Shell

| Tool | Package | What it does |
|------|---------|--------------|
| **atuin** | `atuin` | Replaces shell history with a searchable SQLite database. Remembers working dir, exit code, git branch per command. Syncs across machines. Makes Ctrl+R actually useful. |
| **zoxide** | `zoxide` | Smart `cd` replacement. Learn your directory patterns so `z proj` jumps to `~/projects/my-arch-config` instantly. Rust-based. |
| **zellij** | `zellij` | Modern terminal multiplexer (alternative to tmux). Works out of the box with no config, resizable panes, tab bar. Good if you want tmux-like sessions without the learning curve. |
| **tmux** | `tmux` | Battle-tested terminal multiplexer. Persistent sessions survive disconnects. Huge ecosystem of plugins. More complex than zellij but more compatible everywhere. |
| **eza** | `eza` | Modern `ls` replacement. Shows git status per file, tree view, icons with nerd fonts. Colorized and much more readable than plain ls. |
| **ripgrep** | `ripgrep` | Fast `grep` replacement. Automatically skips `.git`, `node_modules`, `.venv`. Much faster than grep for searching code. |
| **delta** | `git-delta` | Better git diff viewer. Syntax-highlighted diffs with side-by-side mode and line numbers. Set as your core.pager in git config. |
| **lazygit** | `lazygit` | TUI for git. Interactive staging, rebasing, cherry-picking. Never type `git rebase -i` again. |
| **glow** | `glow` | Renders markdown beautifully in the terminal. Useful for reading READMEs and docs without leaving the terminal. |
| **direnv** | `direnv` | Auto-loads `.env` files and switches language versions when you `cd` into a project. Works with nvm, uv, etc. via `.envrc` files. |

---

## System Monitoring

| Tool | Package | What it does |
|------|---------|--------------|
| **btop** | `btop` | Beautiful TUI system monitor. Per-core CPU graphs, memory, disk I/O, network, and process tree. Way better looking than htop. |
| **nvtop** | `nvtop` | GPU monitoring like htop but for GPUs. Shows utilization, memory, temperature, power draw per process. Good for your AMD ROCm setup. |
| **lm_sensors** | `lm_sensors` | Reads CPU and motherboard temperatures. Can feed live temps into your polybar via a custom block. |

---

## i3 / Desktop Enhancements

| Tool | Package | What it does |
|------|---------|--------------|
| **picom** | `picom` | Compositor for i3. Eliminates screen tearing, enables window transparency and blur effects. Many rices use this. Lightweight. |
| **redshift** | `redshift` | Adjusts screen color temperature based on time of day (warm at night). Reduces eye strain. Similar to f.lux. |
| **flameshot** | `flameshot` | More powerful screenshot tool than maim. Has a GUI annotation mode (draw arrows, text, blur). Still scriptable. |
| **variety** | `variety` (AUR) | Wallpaper changer with scheduling, image sources (Unsplash, Flickr, local), and effects. More features than a plain feh script. |
| **xidlehook** | `xidlehook` (AUR) | Runs scripts on idle (e.g. dim screen, then lock). More flexible than xautolock or xss-lock alone. |

---

## Rofi Extensions

These are shell scripts that plug into rofi as custom modes:

| Script | What it does |
|--------|--------------|
| **rofi-bluetooth** | Bluetooth device menu via bluetoothctl. Connect/disconnect devices without opening blueman. |
| **rofi-wifi** | WiFi network picker using nmcli. Switch networks from a rofi menu. |
| **rofi-emoji** | Emoji/unicode picker. Search and copy any emoji to clipboard. |
| **rofi-calc** | Calculator inside rofi. Type math expressions and get results. |

Search GitHub for these — they're single-file scripts, not packaged. Drop them in `~/.config/bin/`.

---

## Media

| Tool | Package | What it does |
|------|---------|--------------|
| **mpv** | `mpv` | Lightweight, scriptable video/audio player. Handles everything ffmpeg can. Better than VLC for keyboard-driven use. |
| **cava** | `cava` | Terminal audio spectrum visualizer. Looks great in a floating kitty window or as a polybar module. |
| **ncspot** | `ncspot` (AUR) | TUI Spotify client. Control Spotify from the terminal without opening the Electron app. |

---

## Security & Privacy

| Tool | Package | What it does |
|------|---------|--------------|
| **keepassxc** | `keepassxc` | Local password manager with a proper GUI. Stores everything in an encrypted `.kdbx` file. No cloud, fully offline. |
| **bitwarden** | `bitwarden` | Cloud-synced password manager with browser extension. Good if you want sync across devices. Open-source server. |
| **lynis** | `lynis` | Security auditing tool. Run `sudo lynis audit system` to get a report of hardening opportunities. |
| **ufw** | `ufw` | Simple firewall frontend for iptables. `ufw enable` and you're done. |

---

## Development

| Tool | Package | What it does |
|------|---------|--------------|
| **docker** | `docker` + `docker-compose` | Container runtime. Essential for running services locally without polluting your system. |
| **podman** | `podman` | Docker-compatible container runtime without a daemon. Runs containers rootless by default. More secure. |
| **neovim** | `neovim` | Modern vim fork with Lua config, LSP support, plugin ecosystem. Good as a vim upgrade if you spend a lot of time in terminal editors. |

---

## Wayland (future)

Not urgent since you're on X11/i3, but worth knowing when you're ready to move:

| Tool | What it does |
|------|--------------|
| **Hyprland** | Wayland compositor with i3-like keybinds + animations + fancy tiling. The most popular "rice" WM on r/unixporn right now. |
| **Waybar** | Polybar equivalent for Wayland. Drop-in visual replacement. |
| **swaylock** | i3lock equivalent for Wayland. |
| **wl-clipboard** | xclip equivalent for Wayland. |
| **grim + slurp** | maim equivalent for Wayland (screenshot tools). |

Migration path: `i3 → sway` (minimal change, same config syntax) or `i3 → Hyprland` (more effort, nicer visuals).

---

## Backup & Sync

| Tool | Package | What it does |
|------|---------|--------------|
| **syncthing** | `syncthing` | Peer-to-peer file sync across your devices. No cloud, no account. Good for syncing notes, files between PC and laptop. |
| **restic** | `restic` | Fast, encrypted backup tool. Works with local drives, S3, SFTP. Simple CLI. |
| **timeshift** | `timeshift` (AUR) | System snapshots using rsync or btrfs. One-command rollback if an update breaks something. |
