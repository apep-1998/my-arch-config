# Arch Linux Installer — Claude Code Context

This is a modular Arch Linux post-install script. It installs a full i3-based desktop environment by combining a shared base with machine-specific and profile-specific layers.

## What This Project Does

`install.sh` is the entry point. It asks interactively for:
- **Machine**: `pc` (AMD GPU + ROCm) or `laptop` (Intel Iris Xe + TLP)
- **Profile**: `personal` (user: arsham) or `work` (user: everphone)
- **Username**: who to configure

It then installs packages and applies dotfiles in order:
`base → machine → base AUR → machine AUR → profile → profile AUR → dotfiles → services`

## Project Layout

```
install.sh                      ← main script, contains all logic
base/packages.txt               ← pacman packages for every setup
base/aur-packages.txt           ← AUR packages for every setup
machines/pc/packages.txt        ← AMD GPU + ROCm (pacman)
machines/pc/aur-packages.txt    ← PC-only AUR packages
machines/pc/setup.sh            ← PC post-install (ROCm env, video group)
machines/laptop/packages.txt    ← Intel GPU + TLP (pacman)
machines/laptop/aur-packages.txt ← laptop-only AUR (auto-cpufreq)
machines/laptop/setup.sh        ← laptop post-install (TLP, video group)
profiles/personal/packages.txt  ← personal pacman packages
profiles/personal/aur-packages.txt ← personal AUR packages
profiles/work/packages.txt      ← work pacman packages
profiles/work/aur-packages.txt  ← work AUR (slack-desktop)
dotfiles/                       ← bundled configs (copied/symlinked to ~/dotfiles)
README.md                       ← human-readable documentation
```

## Package File Format

One package per line. Lines starting with `#` and blank lines are ignored.
- `packages.txt` → installed with `pacman -S --needed --noconfirm`
- `aur-packages.txt` → installed with `yay -S --needed --noconfirm`

## Key Decisions

- **Why two layers per machine/profile?** Packages in official repos go in `packages.txt`, AUR packages go in `aur-packages.txt`. They're separate because pacman and yay have different invocation and error behavior.
- **Why bundled dotfiles?** The `dotfiles/` directory is a snapshot so the installer works offline or without a git remote. If the user has a remote repo they provide the URL at runtime.
- **yay build**: yay is bootstrapped by building it from AUR as the target user (non-root), then installing the `.pkg.tar.zst` as root. `go` must be installed via pacman first.
- **No root for yay**: `yay` and `makepkg` must run as non-root. The script uses `sudo -u "$USERNAME"` for all AUR operations.

## Machines

| Machine | GPU | Special packages |
|---------|-----|-----------------|
| `pc` | AMD Radeon | vulkan-radeon, xf86-video-amdgpu, ROCm stack |
| `laptop` | Intel Iris Xe (13th Gen) | vulkan-intel, intel-media-driver, TLP, auto-cpufreq |

## Profiles

| Profile | Default user | Special packages |
|---------|-------------|-----------------|
| `personal` | arsham | dev/AI tools |
| `work` | everphone | slack-desktop |

## Dotfiles Symlink Structure

After install, for the target user:
- `~/.config/greenclip.toml` — copied (clipboard history config)
- `~/.zshrc` → `~/dotfiles/zshrc`
- `~/.config/i3` → `~/dotfiles/config/i3`
- `~/.config/polybar` → `~/dotfiles/config/polybar`
- `~/.config/rofi` → `~/dotfiles/config/rofi`
- `~/.config/dunst` → `~/dotfiles/config/dunst`
- `~/.config/yazi` → `~/dotfiles/config/yazi`
- `~/.config/zed` → `~/dotfiles/config/zed`
- `~/.config/opencode` → `~/dotfiles/config/opencode`
- `~/.p10k.zsh` — copied (not symlinked)
- `~/.config/zsh_aliases` — copied (not symlinked)

## Rules for AI Assistance

**When making any change to this project:**

1. **Always update README.md** to reflect the change. If you add a machine, document it. If you add packages, mention them. If you change install behavior, update the relevant section.

2. **Adding a package**: Put it in the most specific layer that applies. If it's needed everywhere → `base/`. If it's GPU/hardware-dependent → `machines/<machine>/`. If it's use-case-specific → `profiles/<profile>/`. Never add a machine-specific package to `base/`.

3. **Adding a new machine or profile**: Create the full set of files (`packages.txt`, `aur-packages.txt`, optionally `setup.sh`), add the option to `install.sh`'s `select_option` call, update the `DEFAULT_USER` case if it's a profile, and update README.md.

4. **Editing dotfiles**: The `dotfiles/` directory in this repo is a bundled snapshot. If you edit configs here, the same change should be applied to the live `~/dotfiles/` on the actual machine. They are not automatically synced.

5. **install.sh structure**: The 8-step order (update → multilib → base pkgs → machine pkgs → AUR → profile pkgs → dotfiles → services) must be preserved. Steps are numbered in the output — keep that numbering accurate if steps are added or removed.

6. **Every package must have a comment above it** describing what it does in one short line. This applies to every `packages.txt` and `aur-packages.txt` file. When adding a new package, always write the comment on the line directly above the package name — no blank line between the comment and the package. Keep it factual and brief, like:
   ```
   # fast file search (find alternative)
   fd
   # Slack team messaging desktop client
   slack-desktop
   ```
   Never add a package without a comment. Never use vague comments like `# utility` or `# tool`.

7. **Never use `pacman -S` without `--needed`** — this prevents reinstalling already-installed packages.
