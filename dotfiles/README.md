# Dotfiles Repository

This repository contains my personal Linux configuration (dotfiles).

## Configured Apps

- **OpenCode**: Managed in `.config/opencode` and symlinked to `~/.config/opencode`.

## Setup Instructions

To apply these configurations on a new system:

```bash
git clone <this-repo-url> ~/dotfiles
# Use symbolic links to manage configuration files
ln -sf ~/dotfiles/.config/opencode ~/.config/opencode
```
