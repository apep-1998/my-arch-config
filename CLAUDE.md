# my-arch-config — Claude Code Context

This is a single repository that contains everything for my Arch Linux setup: the installer, all dotfiles, and a sync script. There is no separate dotfiles repo — dotfiles live here.

## What This Project Does

- **`install.sh`** — run once on a fresh Arch machine (as root). Installs packages and wires up configs.
- **`sync.sh`** — run after pulling updates from another machine (as root). Re-applies symlinks and installs new packages.
- **`dotfiles/`** — the actual live configs. On any machine, `~/dotfiles/` is a symlink into this directory, wherever the repo was cloned.

`install.sh` asks interactively for:
- **Machine**: `pc` (AMD GPU + ROCm) or `laptop` (Intel Iris Xe + TLP)
- **Profile**: `personal` (user: arsham) or `work` (user: everphone)
- **Username**: who to configure

It then installs packages and applies dotfiles in order:
`base → machine → base AUR → machine AUR → profile → profile AUR → dotfiles → services`

After install, the saved profile is written to `/etc/my-arch/profile` so `sync.sh` can pick it up without asking again.

## Project Layout

```
install.sh                      ← fresh install (run as root)
sync.sh                         ← pull + re-apply (run as root)
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
dotfiles/                       ← all configs — the canonical source
```

## How Dotfiles Work

`~/dotfiles/` is a symlink to `<repo>/dotfiles/` — wherever the repo was cloned. This means:
- Editing `~/.config/i3/config` edits the file in the git repo directly (via symlink chain)
- No copy step, no separate dotfiles repo, no syncing between them
- Clone path doesn't matter: `~/.my-arch-config`, `~/projects/my-arch-config`, `/opt/arch` — all work

## Package File Format

One package per line. Lines starting with `#` and blank lines are ignored.
- `packages.txt` → installed with `pacman -S --needed --noconfirm`
- `aur-packages.txt` → installed with `yay -S --needed --noconfirm`

## Key Decisions

- **Why two layers per machine/profile?** Packages in official repos go in `packages.txt`, AUR packages go in `aur-packages.txt`. They're separate because pacman and yay have different invocation and error behavior.
- **Why symlink instead of copy?** So every edit to a config is immediately tracked in git. No manual sync needed.
- **yay build**: bootstrapped by building from AUR as the target user (non-root), then installing the `.pkg.tar.zst` as root. `go` must be installed via pacman first.
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
- `~/dotfiles/` → `<repo>/dotfiles/` (the repo itself)
- `~/.zshrc` → `~/dotfiles/zshrc`
- `~/.config/<app>` → `~/dotfiles/config/<app>` for every subdirectory in `dotfiles/config/`
- `~/.p10k.zsh` — copied (not symlinked, may have per-machine tweaks)
- `~/.config/zsh_aliases` — copied (may have per-machine overrides)
- `~/.config/greenclip.toml` — copied (clipboard history config)

## Rules for AI Assistance

**When making any change to this project:**

1. **Always update README.md** to reflect the change. If you add a machine, document it. If you add packages, mention them. If you change install behavior, update the relevant section.

2. **Adding a package**: Put it in the most specific layer that applies. If it's needed everywhere → `base/`. If it's GPU/hardware-dependent → `machines/<machine>/`. If it's use-case-specific → `profiles/<profile>/`. Never add a machine-specific package to `base/`.

3. **Adding a new machine or profile**: Create the full set of files (`packages.txt`, `aur-packages.txt`, optionally `setup.sh`), add the option to `install.sh`'s `select_option` call, update the `DEFAULT_USER` case if it's a profile, and update README.md.

4. **Editing dotfiles**: Edit directly — `dotfiles/` is the live source. Changes here immediately affect the machine via symlinks. No separate sync step needed.

5. **install.sh / sync.sh structure**: The 8-step order in install.sh and 3-step order in sync.sh must be preserved. Keep step numbers in the output accurate if steps change.

6. **Every package must have a comment above it** describing what it does in one short line. This applies to every `packages.txt` and `aur-packages.txt` file. When adding a new package, always write the comment on the line directly above the package name — no blank line between the comment and the package. Keep it factual and brief, like:
   ```
   # fast file search (find alternative)
   fd
   # Slack team messaging desktop client
   slack-desktop
   ```
   Never add a package without a comment. Never use vague comments like `# utility` or `# tool`.

7. **Never use `pacman -S` without `--needed`** — this prevents reinstalling already-installed packages.
